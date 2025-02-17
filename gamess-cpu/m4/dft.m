_IF(old-dft)
      subroutine scdft(vect,dftcor,wei,totcen,imode)
c
c calculate the fock matrix correction corresponding 
c to the required density functional correlation correction
c
c  imode = 0   ecorr and density - alter ehf etc
c  imode = 1   ecorr, density, (for checks) and fock matrix contributions
c
c if odenpt = .true., just evaluate at one point, and print out values
c
      implicit REAL (a-h,o-z)
      logical odiis,odenpt
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/scfwfn)
INCLUDE(common/nshel)
      common/scfopt/maxit,mconv,nconv,npunch,accdi1,accdi2,odiis
     *,icoupl(3),dmpcut,
     *            acurcy,en,etxt,ehf,ehf0,diff,iter,icount
     *            ,rshift,exttol,dmptol,vshtol,iextin
     *            ,iterv,damp,damp0,diffd,diffp,diffpp,de,deavg,diffsp
      common/dnfdbg/denptx,denpty,denptz,odenpt
INCLUDE(common/dnfnw)
INCLUDE(common/field)
INCLUDE(common/angxyz)
INCLUDE(common/radxxx)
INCLUDE(common/phycon)
c
      dimension vect(*), dftcor(*), wei(*)
      dimension xangx(840), yangy(840), zangz(840)
      equivalence (xr1(1),xangx(1)), (xr2(1),yangy(1)),
     $     (xr3(1),zangz(1))
c
      data zero, half /0.d0, 0.5d0 /
c     data one,two /1.d0, 2.d0 /
c     data pi /3.141592653589793d0/
c
c     pi8= pi/8.d0
c
      write(iwr,*)'scdft'
      write(iwr,*)'nomo, eltot',nomo,eltot
c
c      start loop over the atomic centers
c      integration on the atomic grid
c
      totden=zero
      totcen=zero
      nucpre=0
      if(osc)call vclr(dftcor,1,nx)
      if(odenpt)then
         xip = denptx
         yip = denpty
         zip = denptz
         if(idenfu.eq.1)then
            if(imode.eq.0)then
               call crenp1(xip,yip,zip,vect,nomo,rho,ecorr)
            else
               call caserr('requested sc functional not available')
            endif
         else if(idenfu.eq.2)then
            call crenp2(xip,yip,zip,vect,rho,ecorr,
     &           dftcor,1.0d0,imode)
         else if(idenfu.eq.3.or.idenfu.eq.4)then
            if(imode.eq.0)then
               call crenp3(xip,yip,zip,vect,nomo,rho,ecorr)
            else
               call caserr('requested sc functional not available')
            endif
         else if(idenfu.eq.5)then
            call dslat
c    &           (vect,dftcor,1.0d0,xip,yip,zip,rho,ecorr,imode)
         else
            call caserr('functional not available')
         endif
c     
         write(iwr,*)'single point df calc gave rho, ecorr',rho,ecorr
         write(iwr,*)'point is',denptx,denpty,denptz
         return
      endif
      ipt = 0
      do 400 iat = 1, nat
c        tim1=cpulft(1)
c          if(ndeg(iat).ne.0) goto 500
c
         xiat=c(1,iat)
         yiat=c(2,iat)
         ziat=c(3,iat)
c     nuciat=czan(iat)+0.1
         nuciat=czanr(iat)+0.1d0
         if(nuciat.ne.nucpre ) then
            nucpre=nuciat
            call raddat (nuciat)
            tt =rm( nuciat)
            tt = tt/toang(1)
            if(nuciat.gt.1)  tt=tt*half
            tt3=tt*tt*tt
            call dscal(nrad,tt3, wcg,1)
            call dscal(nrad, tt, rcg,1)
         endif
         do 300 ir=1,nrad
            rr=rcg(ir)
            do 200 iang=1,nang
               xip=xr1(iang)*rr+xiat
               yip=yr1(iang)*rr+yiat
               zip=zr1(iang)*rr+ziat
               
               ipt = ipt + 1
c
c call routine to build all fock matrix contributions
c from this grid point
c
               if(idenfu.eq.1)then
                  if(imode.eq.0)then
                     call crenp1(xip,yip,zip,vect,nomo,rho,ecorr)
                  else
                  call caserr('requested sc functional not available')
                  endif
               else if(idenfu.eq.2)then
                  call crenp2(xip,yip,zip,vect,rho,ecorr,
     &                 dftcor, wei(ipt),imode)
               else if(idenfu.eq.3.or.idenfu.eq.4)then
                  if(imode.eq.0)then
                     call crenp3(xip,yip,zip,vect,nomo,rho,ecorr)
                  else
                  call caserr('requested sc functional not available')
                  endif
               else if(idenfu.eq.5)then
                  call dslat
c    &               (vect,dftcor,wei(ipt),xip,yip,zip,rho,ecorr,imode)
               else
                  call caserr('functional not available')
               endif
c
               totden = totden + wei(ipt)*rho
               totcen = totcen + wei(ipt)*ecorr
c               write(iwr,*)ipt,rho,wei(ipt)*rho
 200        continue
 300     continue
 400  continue
c
      write(iwr,*)'eltot,totden',eltot,totden
      factx=eltot/totden
      if(imode.eq.0)write(iwr,9920) totden,totcen,factx
      totcen = totcen*factx
      totden = totden*factx

      if(imode.eq.1)call dscal(nx,factx,dftcor,1)

      if(imode.eq.0)then
         ehfx=ehf
         if(dabs(ehfx+en).le.1.d-5) ehfx=ehf0
         etot=ehfx+en
         toten=etot+totcen
         write(iwr,9930) totden,totcen, en,ehfx,etot,toten
      endif
c9800 format(//,5x,60('-'),/,5x,a60,/,5x,a60,/,5x,60('-'),/)

 9920 format(/,5x,'Total Density           ',f20.10,/,
     $         5x,'Total Correlation Energy',f20.10,/,
     $         5x,'Renormalization Factor  ',f20.10,/)
 9930 format(/,5x,'Total Density           ',f20.10,/,
     $         5x,'Total Correlation Energy',f20.10,/,
     $         5x,'Nuclear Repulsion       ',f20.10,/,
     $         5x,'Electronic Energy       ',f20.10,/,
     $         5x,'HF Energy               ',f20.10,/,
     $         5x,'Total Energy (HF+Corr.) ',f20.10,/)
c9941 format(3f15.8,2f20.10)
      return
      end
c
      subroutine scdfoc(pop,noc)
      implicit REAL (a-h,o-z)
c
INCLUDE(common/dnfnw)
INCLUDE(common/iofile)
c
c
       dimension pop(*)
       data zero, one,two /0.d0, 1.d0, 2.d0 /
c      data half / 0.5d0 /
c
c      set up alpha and beta occupation numbers - 
c      closed shell only
c
      eltot=zero
      nomo = noc
      small = 1.0d-10
      do 600 i=1,noc
         if(pop(i).lt.-small)then
            call caserr('-ve pop in scdfoc')
         else if(pop(i).lt.small)then
            occa(i)=zero
            occb(i)=zero
         else if(pop(i).lt.2.0d0-small)then
            call caserr('pop in scdfoc ne 2')
         else if(pop(i).lt.2.0d0+small)then
            occa(i)=one
            occb(i)=one
            eltot=eltot+two
            nomo = i
         else 
            write(iwr,*)noc,i,pop(i)
            call caserr('pop gt 2 in scdfoc')
         endif
600    continue
       
       write(iwr,*)'density functional type is',idenfu
       write(iwr,*)'osc is ',osc
       if(ncorxx.gt.0) then
          do 630 i=1,ncorxx
             occa(i)=zero
             occb(i)=zero
             eltot=eltot-two
 630      continue
       end if
       write(iwr,5410)
5410   format(/,5x,'orbital     alpha occ.      beta occ. ')
       write(iwr,5420) (i,occa(i),occb(i),i=1,nomo)
5420   format(7x,i3,5x,f10.4,5x,f10.4)
       return
       end
      subroutine scdfgr(wei,nmax,npts)
c
c  set up grid weighting factors for Becke grid.
c
      implicit REAL (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/dnfnw)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/field)
INCLUDE(common/angxyz)
INCLUDE(common/radxxx)
INCLUDE(common/phycon)

      dimension xangx(840), yangy(840), zangz(840)
      equivalence (xr1(1),xangx(1)), (xr2(1),yangy(1)),
     $             (xr3(1),zangz(1))
      dimension wei(*)
c
      data zero, half, one /0.d0, 0.5d0, 1.d0 /
c     data two / 2.d0 /
      data pi /3.141592653589793d0/

c     set up constants for integration
      pi8= pi/8.d0
      if(nangpr.eq.1) factx=one
      if(nangpr.eq.2) factx=pi8
      if(nangpr.eq.3) factx=4.d0*pi
      if ( nangpr.eq. 1 )  then
         do 1 i=1,840
 1          xangx(i)=zangz(i)
         nang=nangz
      endif
      if ( nangpr.eq. 3 )  then
         do 2 i=1,840
 2          xangx(i)=yangy(i)
         nang=nangy
      endif


c     interatomic distances
      ij=0
      do 20 iat=1,nat
         ndeg(iat)=0
         do 20 jat=1,iat
            tt=zero
            if(iat.eq.jat) goto 10
            tt=(c(1,iat)-c(1,jat))**2 + (c(2,iat)-c(2,jat))**2 +
     *           (c(3,iat)-c(3,jat))**2
            tt= one/  dsqrt(tt)
 10      ij=ij+1
         rij(ij)=tt
 20   continue
c
c - no symmetry at present 
c       if(osymm) call symeqv
c
c      start loop over the atomic centers
c      generation of the grid  and integration within the atomic grid
c
       npts = 0
       nucpre=0
       do 400 iat = 1, nat
c         tim1=cpulft(1)
          if(ndeg(iat).ne.0) goto 500
c
          xiat=c(1,iat)
          yiat=c(2,iat)
          ziat=c(3,iat)
c     nuciat=czan(iat)+0.1
          nuciat=czanr(iat)+0.1d0
          if(nuciat.ne.nucpre ) then
             nucpre=nuciat
             call raddat (nuciat)
             tt =rm( nuciat)
             tt = tt/toang(1)
             if(nuciat.gt.1)  tt=tt*half
             tt3=tt*tt*tt
             call dscal(nrad,tt3, wcg,1)
             call dscal(nrad, tt, rcg,1)
          endif
          write(iwr,7111) iat,nuciat,rm(nuciat),nrad,nang
 7111     format(' iat, nuciat, rm, nrad, nang',2i5,g20.10,2i5)

          do 300 ir=1,nrad
             rr=rcg(ir)
             do 200 iang=1,nang
                xip=xr1(iang)*rr+xiat
                yip=yr1(iang)*rr+yiat
                zip=zr1(iang)*rr+ziat
c
                ptot=zero
                do 60 jat=1,nat
                   pir=one
                   rj= (xip-c(1,jat))**2 + (yip-c(2,jat))**2 +
     $                  (zip-c(3,jat))**2
                   rj= dsqrt(rj)
                   do 50 kat=1,nat
                      if(kat.ne.jat)then
                         if(kat.gt.jat)then
                            jkat=(kat*(kat-1))/2+jat
                         else
                            jkat=(jat*(jat-1))/2+kat
                         endif
                         rjk=rij(jkat)
                         rk= (xip-c(1,kat))**2 + (yip-c(2,kat))**2 +
     $                        (zip-c(3,kat))**2
                         rk= dsqrt(rk)
                         amu=(rj-rk)*rjk
                         smu=smuf(amu)
                         pir=pir*smu
                      endif
 50                continue
                   if(jat.eq.iat) priat=pir
                   ptot=ptot+pir
 60             continue
                
                npts = npts + 1
                if(npts.gt.nmax)call caserr('memory overflow')
                wei(npts) = factx*wr1(iang)*wcg(ir)*priat/ptot
c                write(iwr,*)'factx*wr1(iang)*wcg(ir)*priat/ptot',factx,
c     &               wr1(iang),wcg(ir),priat,ptot
 200         continue
 300      continue
 500      continue
 400   continue
      return
      end
      subroutine dslat
c     subroutine dslat(vect,dftcor,w,xip,yip,zip,rho,ecorr,imode)
      implicit REAL (a-h,o-z)
c     dimension vect(*), dftcor(*)
c
c correlation functional kn**4/3
c
      call caserr('slater correlation not implemented')
      return
      end
_EXTRACT(becke,hp800)
      subroutine becke (vmo,icase)
      implicit REAL  (a-h,o-z)
      character * 60 texta(4), textb(4)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/scfwfn)
INCLUDE(common/nshel)
INCLUDE(common/scfopt)
INCLUDE(common/dnfnw)
INCLUDE(common/field)
INCLUDE(common/angxyz)
INCLUDE(common/radxxx)
INCLUDE(common/phycon)
       dimension vmo(*)
       dimension rhorad(50), rhoang(210), ecrrad(50), ecrang(210)
       dimension xangx(840), yangy(840), zangz(840)
       equivalence (xr1(1),xangx(1)), (xr2(1),yangy(1)),
     $             (xr3(1),zangz(1))
c
       data zero, half, one,two /0.d0, 0.5d0, 1.d0, 2.d0 /
       data pi /3.141592653589793d0/
       data texta(1)/
     $ 'CORRELATION ENERGY FROM NON-LOCAL DENSITY FUNCTIONAL        '/
       data texta(2)/
     $ 'CORRELATION ENERGY FROM NON-LOCAL DENSITY FUNCTIONAL        '/
       data texta(3)/
     $ 'CORRELATION ENERGY FROM LOCAL DENSITY FUNCTIONAL            '/
       data texta(4)/
     $ 'CORRELATION ENERGY FROM LOCAL DENSITY FUNCTIONAL            '/
       data textb(1)/
     $ 'Lee-Yang-Parr formula (Colle-Salvetti)                      '/
       data textb(2)/
     $ 'Lee-Yang-Parr formula with 2nd order gradient expansion     '/
       data textb(3)/
     $ 'Vosko-Wilk-Nusair formula                                   '/
       data textb(4)/
     $ 'Vosko-Wilk-Nusair formula corrected for Self-Interaction    '/
       pi8= pi/8.d0
c
c      set up constants for integration
       pi8= pi/8.d0
       if(nangpr.eq.1) factx=one
       if(nangpr.eq.2) factx=pi8
       if(nangpr.eq.3) factx=4.d0*pi
       if ( nangpr.eq. 1 )  then
           do 1 i=1,840
1           xangx(i)=zangz(i)
           nang=nangz
       endif
       if ( nangpr.eq. 3 )  then
           do 2 i=1,840
2           xangx(i)=yangy(i)
           nang=nangy
       endif
c
c
c      set up alpha and beta occupation numbers
c      icase=1  closed shell
c            2  restricted open shell (multiplicity 1,2,3,4)
c            3  uhf - not implemented
c
       eltot=zero
       goto (5100,5200,5300),icase
5100   continue
       nomo=na
       do 600 i=1,nomo
         occa(i)=one
         occb(i)=one
         eltot=eltot+two
600    continue
       goto 5400
5200   continue
       nomo=nco
       do 610 i=1,nomo
         occa(i)=one
         occb(i)=one
         eltot=eltot+two
610    continue
       if(mul.gt.4)
     + call caserr('DF calcs. not implemented for mult > 4')
       if(mul.gt.1) goto 5201
       nomo=nomo+1
       occa(nomo)=one
       occb(nomo)=zero
       nomo=nomo+1
       occb(nomo)=one
       occa(nomo)=zero
       eltot=eltot+two
       goto 5400
5201   continue
       nomo1=nomo+1
       nomo2=nomo+mul-1
       do 620 i=nomo1,nomo2
       occa(i   )=one
       occb(i   )=zero
       eltot=eltot+one
620    continue
       nomo=nomo2
       goto 5400
5300   call caserr('DF calcs. not implemented for UHF wfn')
5400   continue
       if(ncorxx.gt.0) then
             do 630 i=1,ncorxx
             occa(i)=zero
             occb(i)=zero
             eltot=eltot-two
630          continue
       end if
       write(iwr,9800) texta(idenfu),textb(idenfu)
       write(iwr,5410)
5410   format(/,5x,'orbital     alpha occ.      beta occ. ')
       write(iwr,5420) (i,occa(i),occb(i),i=1,nomo)
5420   format(7x,i3,5x,f10.4,5x,f10.4)
c
c      interatomic distances
       ij=0
       do 20 iat=1,nat
       ndeg(iat)=0
       do 20 jat=1,iat
       tt=zero
       if(iat.eq.jat) goto 10
       tt=(c(1,iat)-c(1,jat))**2 + (c(2,iat)-c(2,jat))**2 +
     *    (c(3,iat)-c(3,jat))**2
       tt= one/  dsqrt(tt)
10     ij=ij+1
       rij(ij)=tt
20     continue
       if(osymm) call symeqv(iwr)
c
c      start loop over the atomic centers
c      generation of the grid  and integration within the atomic grid
c
       nucpre=0
       do 400 iat = 1, nat
       tim1=cpulft(1)
       if(ndeg(iat).ne.0) goto 500
c
       xiat=c(1,iat)
       yiat=c(2,iat)
       ziat=c(3,iat)
c      nuciat=czan(iat)+0.1e0
       nuciat=czanr(iat)+0.1d0
       if(nuciat.eq.nucpre ) goto 290
       nucpre=nuciat
       call raddat (nuciat)
       tt =rm( nuciat)
       tt = tt/toang(1)
       if(nuciat.gt.1)  tt=tt*half
       tt3=tt*tt*tt
       call dscal(nrad,tt3, wcg,1)
       call dscal(nrad, tt, rcg,1)
290    continue
       write(iwr,7111) iat,nuciat,rm(nuciat),nrad,nang
7111  format(' iat, nuciat, rm, nrad, nang',2i5,g20.10,2i5)
       do 300 loop=1,nrad
       rr=rcg(loop)
       do 200 iang=1,nang
       xip=xr1(iang)*rr+xiat
       yip=yr1(iang)*rr+yiat
       zip=zr1(iang)*rr+ziat
c
                   ptot=zero
                   do 60 jat=1,nat
                   pir=one
                   rj= (xip-c(1,jat))**2 + (yip-c(2,jat))**2 +
     $                 (zip-c(3,jat))**2
                   rj= dsqrt(rj)
                   do 50 kat=1,nat
                   if(kat -  jat) 51,50,52
51                 jkat=(jat*(jat-1))/2+kat
                   goto 53
52                 jkat=(kat*(kat-1))/2+jat
53                 rjk=rij(jkat)
                   rk= (xip-c(1,kat))**2 + (yip-c(2,kat))**2 +
     $                 (zip-c(3,kat))**2
                   rk= dsqrt(rk)
                   amu=(rj-rk)*rjk
                   smu=smuf(amu)
                   pir=pir*smu
50                 continue
                   if(jat.eq.iat) priat=pir
                   ptot=ptot+pir
60                 continue
       priat= priat/ptot
       if(idenfu.eq.1)
     $ call crenp1(xip,yip,zip,vmo,nomo,rho,ecorr)
       if(idenfu.eq.2)
_IF1()cdft
     $ call crenp2(xip,yip,zip,vmo,rho,ecorr,hdum,wdum,0)
       if(idenfu.eq.3. or . idenfu.eq.4)
     $ call crenp3(xip,yip,zip,vmo,nomo,rho,ecorr)
c
       rhoang (iang) =   rho  * priat
       ecrang (iang) =   ecorr* priat
200    continue
       rhorad(loop  )  = ddot(nang, rhoang,1, wr1, 1)
       ecrrad(loop  )  = ddot(nang, ecrang,1, wr1, 1)
300    continue
       densia = ddot(nrad, rhorad,1,wcg,1)
       corena = ddot(nrad, ecrrad,1,wcg,1)
       denat(iat)     = densia * factx
       encoat(iat)    = corena * factx
       tim2=cpulft(1)
       timat(iat)= tim2-tim1
       goto 400
500    continue
c
c      set up data for equivalent atoms
       kat=ndeg(iat)
       denat(iat)     = denat(kat)
       encoat(iat)    = encoat(kat)
       tim2=cpulft(1)
       timat(iat)= tim2-tim1
400    continue
c
c      print out final results
       totden=zero
       totcen=zero
       write(iwr,9900)
       do 640 iat=1,nat
         write(iwr,9910) iat, denat(iat),encoat(iat),timat(iat)
         totden=totden+denat(iat)
         totcen=totcen+encoat(iat)
640    continue
       factx=eltot/totden
          write(iwr,9920) totden,totcen,factx
       totden=zero
       totcen=zero
       write(iwr,9810)
       write(iwr,9900)
       do 650 iat=1,nat
         denat(iat)=denat(iat)*factx
         encoat(iat)=encoat(iat)*factx
         write(iwr,9910) iat, denat(iat),encoat(iat),timat(iat)
         totden=totden+denat(iat)
         totcen=totcen+encoat(iat)
650    continue
         ehfx=ehf
         if(dabs(ehfx+en).le.1.d-5) ehfx=ehf0
         etotal=ehfx+en
         toten=etotal+totcen
          write(iwr,9930) totden,totcen, en,ehfx,etotal,toten
         if(.not.ofield) return
         iunfld=25
         rewind iunfld
         write(iunfld,9941) fieldx,fieldy,fieldz,etotal,toten
9800  format(//,5x,60('-'),/,5x,a60,/,5x,a60,/,5x,60('-'),/)
9810  format(//,5x,'After renormalization .....')
9900  format(5x,'atom    density      correlation energy     time(s)',/)
9910  format(7x,i3,f11.6,f24.8,f12.2)
9920  format(/,5x,'Total Density           ',f20.10,/,
     $         5x,'Total Correlation Energy',f20.10,/,
     $         5x,'Renormalization Factor  ',f20.10,/)
9930  format(/,5x,'Total Density           ',f20.10,/,
     $         5x,'Total Correlation Energy',f20.10,/,
     $         5x,'Nuclear Repulsion       ',f20.10,/,
     $         5x,'Electronic Energy       ',f20.10,/,
     $         5x,'HF Energy               ',f20.10,/,
     $         5x,'Total Energy (HF+Corr.) ',f20.10,/)
9941  format(3f15.8,2f20.10)
       return
       end
_ENDEXTRACT
      subroutine crenp1(xp,yp,zp,vmo,nomos,rho,ecorr)
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/dnfnw)
      dimension vmo(*)
      common /coldat/ acost, bcost, ccost, dcost
c
c     crenp1 compute the total density and the associated  correlation
c     energy at a given point (xp, yp, zp)
c     the values are obtained summing up over the mo's
c     crenp1 uses the parr's version of the colle-salvetti functional
      data zero, one, two, pt33, onept6 /0.d0, 1.d0, 2.d0,
     $  0.333333333333333d0, 1.666666666666666d0/
      data pt5, pt25 / 0.5d0, 0.25d0/
      data thresh /1.d-15/
      call vclr( vg ,1,num)
      call vclr( gxp ,1,num)
      call vclr( gyp ,1,num)
      call vclr( gzp ,1,num)
      call vclr( d2 ,1,num)
      call gaupt(xp,yp,zp)
      rhoa=zero
      rhob=zero
      ecorr=zero
          ind=-num+1
          do  90 imo=1,nomos
          ind=ind+num
         valmo(imo)=zero
         occ=occa(imo)+occb(imo)
         if(occ.lt.1.d-6) goto 90
          valmo(imo) =ddot(num, vmo(ind),1, vg, 1)
         vgmo= valmo(imo)
         vgmo=vgmo*vgmo
          rhoa= rhoa + vgmo*occa(imo)
          rhob= rhob + vgmo*occb(imo)
90        continue
          rho = rhoa + rhob
          if(rho.le.thresh) return
      dr2a =zero
      dr2b =zero
      dr2x =zero
      dr2y =zero
      dr2z =zero
      d2ra=zero
      d2rb=zero
      d2r =zero
          ind=-num+1
          do 100 imo=1,nomos
          occ=occa(imo)+occb(imo)
          ind=ind+num
         if(occ.lt.1.d-6) goto 100
          vgmo=valmo(imo)
          gxmo=ddot(num, vmo(ind),1, gxp, 1)
          gymo=ddot(num, vmo(ind),1, gyp, 1)
          gzmo=ddot(num, vmo(ind),1, gzp, 1)
          d2mo=ddot(num, vmo(ind),1, d2, 1)
          ttt = gxmo*gxmo + gymo*gymo + gzmo*gzmo
          dr2a  = dr2a  + occa(imo) * ttt
          dr2b  = dr2b  + occb(imo) * ttt
          ttx = vgmo * gxmo
          tty = vgmo * gymo
          ttz = vgmo * gzmo
          dr2x  = dr2x  + occ       * ttx
          dr2y  = dr2y  + occ       * tty
          dr2z  = dr2z  + occ       * ttz
          ttt = ttt + d2mo * vgmo
          d2ra= d2ra + occa(imo) *  ttt
          d2rb= d2rb + occb(imo) *  ttt
          d2r = d2r  + occ       *  ttt
100       continue
          dr2 = dr2x*dr2x + dr2y*dr2y + dr2z*dr2z
          thfa= pt5 * dr2a - pt25 * d2ra
          thfb= pt5 * dr2b - pt25 * d2rb
          tw  = pt5 * dr2/rho - pt25 * d2r
          gam = two * (one - (rhoa*rhoa + rhob*rhob)/(rho*rho) )
          rho13 = rho** (-pt33)
          rho53 = rho** (-onept6)
          ttt = (rhoa*thfa + rhob*thfb - rho*tw) *  dexp(-ccost*rho13)
          ecorr=-acost*(rho+two*bcost*rho53*ttt)*gam/(one+dcost*rho13)
          return
          end
_IF1()cdft - changes throught crenp2
      subroutine crenp2(xp,yp,zp,vmo,rho,ecorr,h,wei,imode)
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/dnfnw)
      dimension vmo(*),h(*)
      common /coldat/ acost, bcost, ccost, dcost
c
c     crenp2 compute the total density and the associated  correlation
c     energy at a given point (xp, yp, zp)
c     the values are obtained summing up over the mo's
c     crenp2 uses the second-order gradient expansion
c
      data zero, one, two, four, pt33, onept6 /0.d0, 1.d0, 2.d0, 4.0d0,
     $     0.3333333333333333d0, 1.666666666666666d0/
c     data three / 3.0d0/
      data eight, twelve, sevtwo / 8.0d0, 12.0d0, 72.0d0/
      data twenty / 20.0d0/
c     data twott /1.587401051968199d0/
      data cf1 / 2.871234000188191d0/
      data cf1dat /4.557799872345596d0/
      data pt83   /2.666666666666666d0/
      data pt44   /0.444444444444444d0/
      data pt19   /0.1111111111111111d0/
      data pt118  /5.555555555555555d-2/
      data pt5, pt25 / 0.5d0, 0.25d0/
      data thresh /1.d-15/
      data thrshv/1.d-01/
      call vclr( vg ,1,num)
      call vclr( gxp ,1,num)
      call vclr( gyp ,1,num)
      call vclr( gzp ,1,num)
      call vclr( d2 ,1,num)
      call gaupt(xp,yp,zp)
      rhoa=zero
      rhob=zero
      ecorr=zero
      ind=-num+1
      do  90 imo=1,nomo
         ind=ind+num
         valmo(imo)=zero
         occ=occa(imo)+occb(imo)
         if(occ.lt.1.d-6) goto 90
         valmo(imo) =ddot(num, vmo(ind),1, vg, 1)
         vgmo= valmo(imo)
         rhoa= rhoa + vgmo*vgmo*occa(imo)
         rhob= rhob + vgmo*vgmo*occb(imo)
 90   continue
      rho = rhoa + rhob
      if(rho.le.thresh) return
      dr2a =zero
      dr2b =zero
      dr2x =zero
      dr2y =zero
      dr2z =zero
      dr2xa=zero
      dr2ya=zero
      dr2za=zero
      dr2xb=zero
      dr2yb=zero
      dr2zb=zero
      d2ra=zero
      d2rb=zero
      d2r =zero
      ind=-num+1
      do 100 imo=1,nomo
         occ=occa(imo)+occb(imo)
         ind=ind+num
         if(occ.lt.1.d-6) goto 100
         vgmo=valmo(imo)
         gxmo=ddot(num, vmo(ind),1, gx, 1)
         gymo=ddot(num, vmo(ind),1, gy, 1)
         gzmo=ddot(num, vmo(ind),1, gz, 1)
         d2mo=ddot(num, vmo(ind),1, d2, 1)
         ttt = gxmo*gxmo + gymo*gymo + gzmo*gzmo
         dr2a  = dr2a  + occa(imo) * ttt
         dr2b  = dr2b  + occb(imo) * ttt
         ttx = vgmo * gxmo
         tty = vgmo * gymo
         ttz = vgmo * gzmo
         dr2xa = dr2xa + occa(imo) * ttx
         dr2ya = dr2ya + occa(imo) * tty
         dr2za = dr2za + occa(imo) * ttz
         dr2xb = dr2xb + occb(imo) * ttx
         dr2yb = dr2yb + occb(imo) * tty
         dr2zb = dr2zb + occb(imo) * ttz
         dr2x  = dr2x  + occ       * ttx
         dr2y  = dr2y  + occ       * tty
         dr2z  = dr2z  + occ       * ttz
         ttt = ttt + d2mo * vgmo
         d2ra= d2ra + occa(imo) *  ttt
         d2rb= d2rb + occb(imo) *  ttt
         d2r = d2r  + occ       *  ttt
 100  continue
      dr2   = dr2x *dr2x  + dr2y *dr2y  + dr2z *dr2z
      dr2aa = dr2xa*dr2xa + dr2ya*dr2ya + dr2za*dr2za
      dr2bb = dr2xb*dr2xb + dr2yb*dr2yb + dr2zb*dr2zb
c     thfa= pt5 * dr2a - pt25 * d2ra
c     thfb= pt5 * dr2b - pt25 * d2rb
      tw   = pt5 * dr2 /rho  - pt25 * d2r
c---------
      twa  = pt5 * dr2aa/rhoa - pt25 * d2ra
      twb  = pt5 * dr2bb/rhob - pt25 * d2rb
c---------
      gam = two * (one - (rhoa*rhoa + rhob*rhob)/(rho*rho) )
      rho13 = rho** (-pt33)
      rho53 = rho** (-onept6)
      exr13 = dexp(-ccost*rho13)
      odr13 = one+dcost*rho13
      f2 = gam/odr13
      ttt = (cf1dat* (rhoa**pt83 + rhob**pt83) -rho*tw +
     $     pt19 * ( rhoa*twa + rhob*twb) +
     $     pt118* 2.0d0 * ( rhoa*d2ra + rhob * d2rb) ) * exr13
      ecorr=-acost*(rho+two*bcost*rho53*ttt)*f2
c
c-add fock matrix contributions
c
      if(imode.eq.1)then
c
c-closed shell case
c
         rho43 = rho13/rho
         rho73 = rho43/rho
c        rho83 = rho53/rho
         f1 = one/odr13
         g1 = f1*rho53*exr13
         df1 = f1*f1*pt33*dcost*rho43
         t1 = (pt33*ccost*rho43 - onept6/rho + f1*pt33*dcost*rho43)
         dg1 = g1*t1
         dt1 = -pt44*ccost*rho73 + onept6/(rho*rho)
     $         + df1*pt33*dcost*rho43 - f1*pt44*dcost*rho73  
c-       dt1 = -onept6-pt44*rho83*(f1*dcost + ccost/three) +
c-   $         df1*pt33*dcost*rho43   
c-       dg1 = f1*rho53*exr13*pt33*ccost*rho43 + 
c-   $         -f1*exr13*rho83*onept6 + 
c-   $         df1*rho53*exr13
         d2g1 = g1*dt1 + t1*dg1
         t1 = d2g1*rho*dr2*four + dg1*(twelve*dr2 + four*rho*d2r) +
     $        eight*g1*d2r
         t2 = twelve*rho*d2g1*dr2 + dg1*(twenty*dr2 + twelve*rho*d2r) +
     $        eight*g1*d2r
         v = -acost*( rho*df1+f1 +
     $       bcost*cf1*(dg1*rho + pt83*g1)/rho53 + 
     $       bcost*pt25*t1 +
     $       bcost*t2/sevtwo)
         if(v.gt.thrshv)write(6,*)'potential is',v,rho*df1+f1,t1,t2
c
c-build fock matrix contributions
c
         ii = 0
         do 200 i = 1,num
            do 190 j = 1,i
               ii = ii + 1
               h(ii) = h(ii) + wei*v*vg(i)*vg(j)
 190        continue
 200     continue
      endif
c
c-open shell case ..
c
c-       g2 = f2*rho53*exr13
c-       dgam = -four*rhob*(rhoa*rhoa+rhob*rhob)/rho**four
c-       df2 = (odr13*dgam +pt33*gam*dcost*rho43)/(odr13*odr13)
c-       dg2 = f2*rho53*exr13*pt33*ccost*rho43 + 
c-   $         -f2*exr13*rho83*onept6 + 
c-   $         df2*rho53*exr13
c- to be continued
      return
      end
      subroutine crenp3(xp,yp,zp,vmo,nomos,rho,ecorr)
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/dnfnw)
      dimension vmo(*)
      common /coldat/ acost, bcost, ccost, dcost
      data thresh/1.d-15/
      data zero/0.d0/
c
c     crenp3 compute the total density and the associated  correlation
c     energy at a given point (xp, yp, zp)
c     the values are obtained summing up over the mo's
c     crenp3 uses the vosko-wilk-nusair local density expression
c     (can.j.phys. 58, 1200 (1980))
      call vclr( vg ,1,num)
      call gaupt(xp,yp,zp)
      rhoa =zero
      rhob =zero
      ecorr=zero
          ind=-num+1
          do 100 imo=1,nomos
          occ=occa(imo)+occb(imo)
          ind=ind+num
          if(occ.lt.1.d-6) goto 100
          vgmo=ddot(num, vmo(ind),1, vg, 1)
          rhoa= rhoa + vgmo*vgmo*occa(imo)
          rhob= rhob + vgmo*vgmo*occb(imo)
100       continue
          rho = rhoa + rhob
          if(rho.le.thresh) return
       ectot    = ecwvn ( rhoa,rhob)
       ecorr    = ectot * rho
       if( idenfu.lt.4) return
       ecalph   = ecwvn ( rhoa, 0.d0)
       ecbeta   = ecwvn ( 0.d0, rhob)
       ecorr    = ectot * rho  - ecalph * rhoa - ecbeta * rhob
       return
       end
      block data  datang
      implicit REAL  (a-h, o-z)
INCLUDE(common/angxyz)
       common /coldat/ acost, bcost, ccost, dcost
c
      dimension xr11(16), xr12(16),xr13(16),xr14(16),xr15(16),xr16(16),
     $          xr17(16), xr18(16)
      dimension yr11(16), yr12(16),yr13(16),yr14(16),yr15(16),yr16(16),
     $          yr17(16), yr18(16)
      dimension zr11(16), zr12(16),zr13(16),zr14(16),zr15(16),zr16(16),
     $          zr17(16), zr18(16)
      dimension wr11(16), wr12(16),wr13(16),wr14(16),wr15(16),wr16(16),
     $          wr17(16), wr18(16)
      equivalence (xr1(1  ),xr11(1)), (xr1(17 ),xr12(1)),
     $            (xr1(33 ),xr13(1)), (xr1(49 ),xr14(1)),
     $            (xr1(65 ),xr15(1)), (xr1(81 ),xr16(1)),
     $            (xr1(97 ),xr17(1)), (xr1(113),xr18(1))
      equivalence (yr1(1  ),yr11(1)), (yr1(17 ),yr12(1)),
     $            (yr1(33 ),yr13(1)), (yr1(49 ),yr14(1)),
     $            (yr1(65 ),yr15(1)), (yr1(81 ),yr16(1)),
     $            (yr1(97 ),yr17(1)), (yr1(113),yr18(1))
      equivalence (zr1(1  ),zr11(1)), (zr1(17 ),zr12(1)),
     $            (zr1(33 ),zr13(1)), (zr1(49 ),zr14(1)),
     $            (zr1(65 ),zr15(1)), (zr1(81 ),zr16(1)),
     $            (zr1(97 ),zr17(1)), (zr1(113),zr18(1))
      equivalence (wr1(1  ),wr11(1)), (wr1(17 ),wr12(1)),
     $            (wr1(33 ),wr13(1)), (wr1(49 ),wr14(1)),
     $            (wr1(65 ),wr15(1)), (wr1(81 ),wr16(1)),
     $            (wr1(97 ),wr17(1)), (wr1(113),wr18(1))
      dimension xr21(30), xr22(30),xr23(30),xr24(30),xr25(30),xr26(30),
     $          xr27(30)
      dimension yr21(30), yr22(30),yr23(30),yr24(30),yr25(30),yr26(30),
     $          yr27(30)
      dimension zr21(30), zr22(30),zr23(30),zr24(30),zr25(30),zr26(30),
     $          zr27(30)
      dimension wr21(30), wr22(30),wr23(30),wr24(30),wr25(30),wr26(30),
     $          wr27(30)
      equivalence (xr2(1  ),xr21(1)), (xr2(31 ),xr22(1)),
     $            (xr2(61 ),xr23(1)), (xr2(91 ),xr24(1)),
     $            (xr2(121),xr25(1)), (xr2(151),xr26(1)),
     $            (xr2(181),xr27(1))
      equivalence (yr2(1  ),yr21(1)), (yr2(31 ),yr22(1)),
     $            (yr2(61 ),yr23(1)), (yr2(91 ),yr24(1)),
     $            (yr2(121),yr25(1)), (yr2(151),yr26(1)),
     $            (yr2(181),yr27(1))
      equivalence (zr2(1  ),zr21(1)), (zr2(31 ),zr22(1)),
     $            (zr2(61 ),zr23(1)), (zr2(91 ),zr24(1)),
     $            (zr2(121),zr25(1)), (zr2(151),zr26(1)),
     $            (zr2(181),zr27(1))
      equivalence (wr2(1  ),wr21(1)), (wr2(31 ),wr22(1)),
     $            (wr2(61 ),wr23(1)), (wr2(91 ),wr24(1)),
     $            (wr2(121),wr25(1)), (wr2(151),wr26(1)),
     $            (wr2(181),wr27(1))
      dimension xr31(18), xr32(18),xr33(18),xr34(18)
      dimension yr31(18), yr32(18),yr33(18),yr34(18)
      dimension zr31(18), zr32(18),zr33(18),zr34(18)
      dimension wr31(18), wr32(18),wr33(18),wr34(18)
      equivalence (xr3(1  ),xr31(1)), (xr3(19 ),xr32(1)),
     $            (xr3(37 ),xr33(1)), (xr3(55 ),xr34(1))
      equivalence (yr3(1  ),yr31(1)), (yr3(19 ),yr32(1)),
     $            (yr3(37 ),yr33(1)), (yr3(55 ),yr34(1))
      equivalence (zr3(1  ),zr31(1)), (zr3(19 ),zr32(1)),
     $            (zr3(37 ),zr33(1)), (zr3(55 ),zr34(1))
      equivalence (wr3(1  ),wr31(1)), (wr3(19 ),wr32(1)),
     $            (wr3(37 ),wr33(1)), (wr3(55 ),wr34(1))
      data xr11 /
     $0.257766349147389d+00,0.197285822479483d+00,0.106770317739317d+00,
     $-.142381185974849d-11,-.106770317741948d+00,-.197285822481497d+00,
     $-.257766349148479d+00,-.279004285815128d+00,-.257766349146300d+00,
     $-.197285822477469d+00,-.106770317736686d+00,0.427155948203830d-11,
     $0.106770317744579d+00,0.197285822483510d+00,0.257766349149569d+00,
     $0.279004285815128d+00 /
      data yr11 /
     $0.106770317740632d+00,0.197285822480490d+00,0.257766349147934d+00,
     $0.279004285815128d+00,0.257766349146844d+00,0.197285822478476d+00,
     $0.106770317738002d+00,-.284768567089339d-11,-.106770317743263d+00,
     $-.197285822482503d+00,-.257766349149024d+00,-.279004285815128d+00,
     $-.257766349145755d+00,-.197285822476463d+00,-.106770317735371d+00,
     $0.569543329318320d-11 /
      data zr11 / 16 *
     $-.960289856500000d+00 /
      data wr11 / 16 *
     $0.101228536300000d+00 /
      data xr12 /
     $0.558410493130475d+00,0.427388888358841d+00,0.231301199624076d+00,
     $-.308446577824072d-11,-.231301199629775d+00,-.427388888363203d+00,
     $-.558410493132836d+00,-.604419162326175d+00,-.558410493128114d+00,
     $-.427388888354478d+00,-.231301199618376d+00,0.925366575075038d-11,
     $0.231301199635475d+00,0.427388888367565d+00,0.558410493135197d+00,
     $0.604419162326175d+00 /
      data yr12 /
     $0.231301199626926d+00,0.427388888361022d+00,0.558410493131656d+00,
     $0.604419162326175d+00,0.558410493129295d+00,0.427388888356659d+00,
     $0.231301199621226d+00,-.616906576449555d-11,-.231301199632625d+00,
     $-.427388888365384d+00,-.558410493134016d+00,-.604419162326175d+00,
     $-.558410493126934d+00,-.427388888352297d+00,-.231301199615526d+00,
     $0.123382657370052d-10 /
      data zr12 /  16 *
     $-.796666477400000d+00 /
      data wr12 /  16 *
     $0.222381034500000d+00 /
      data xr13 /
     $0.786012298296122d+00,0.601587768385048d+00,0.325576954143464d+00,
     $-.434165916506918d-11,-.325576954151486d+00,-.601587768391188d+00,
     $-.786012298299445d+00,-.850773581010070d+00,-.786012298292799d+00,
     $-.601587768378908d+00,-.325576954135441d+00,0.130253553145749d-10,
     $0.325576954159509d+00,0.601587768397329d+00,0.786012298302768d+00,
     $0.850773581010070d+00 /
      data yr13 /
     $0.325576954147475d+00,0.601587768388118d+00,0.786012298297783d+00,
     $0.850773581010070d+00,0.786012298294460d+00,0.601587768381978d+00,
     $0.325576954139453d+00,-.868350723982203d-11,-.325576954155498d+00,
     $-.601587768394258d+00,-.786012298301106d+00,-.850773581010070d+00,
     $-.786012298291137d+00,-.601587768375838d+00,-.325576954131430d+00,
     $0.173672033893277d-10 /
      data zr13 /  16 *
     $-.525532409900000d+00 /
      data wr13 /  16 *
     $0.313706645900000d+00 /
      data xr14 /
     $0.908203059505102d+00,0.695108528190370d+00,0.376190024632475d+00,
     $-.501659852599236d-11,-.376190024641745d+00,-.695108528197465d+00,
     $-.908203059508942d+00,-.983031907890531d+00,-.908203059501262d+00,
     $-.695108528183276d+00,-.376190024623205d+00,0.150502321318403d-10,
     $0.376190024651014d+00,0.695108528204560d+00,0.908203059512781d+00,
     $0.983031907890531d+00 /
      data yr14 /
     $0.376190024637110d+00,0.695108528193918d+00,0.908203059507022d+00,
     $0.983031907890531d+00,0.908203059503182d+00,0.695108528186823d+00,
     $0.376190024627840d+00,-.100334153289163d-10,-.376190024646380d+00,
     $-.695108528201012d+00,-.908203059510861d+00,-.983031907890531d+00,
     $-.908203059499343d+00,-.695108528179728d+00,-.376190024618570d+00,
     $0.200670489347643d-10 /
      data zr14 /  16 *
     $-.183434642500000d+00 /
      data wr14 /  16 *
     $0.362683783400000d+00 /
      data xr15 /
     $0.257766349147389d+00,0.197285822479483d+00,0.106770317739317d+00,
     $-.142381185974849d-11,-.106770317741948d+00,-.197285822481497d+00,
     $-.257766349148479d+00,-.279004285815128d+00,-.257766349146300d+00,
     $-.197285822477469d+00,-.106770317736686d+00,0.427155948203830d-11,
     $0.106770317744579d+00,0.197285822483510d+00,0.257766349149569d+00,
     $0.279004285815128d+00 /
      data yr15 /
     $0.106770317740632d+00,0.197285822480490d+00,0.257766349147934d+00,
     $0.279004285815128d+00,0.257766349146844d+00,0.197285822478476d+00,
     $0.106770317738002d+00,-.284768567089339d-11,-.106770317743263d+00,
     $-.197285822482503d+00,-.257766349149024d+00,-.279004285815128d+00,
     $-.257766349145755d+00,-.197285822476463d+00,-.106770317735371d+00,
     $0.569543329318320d-11 /
      data zr15 /  16 *
     $0.960289856500000d+00 /
      data wr15 /  16 *
     $0.101228536300000d+00 /
      data xr16 /
     $0.558410493130475d+00,0.427388888358841d+00,0.231301199624076d+00,
     $-.308446577824072d-11,-.231301199629775d+00,-.427388888363203d+00,
     $-.558410493132836d+00,-.604419162326175d+00,-.558410493128114d+00,
     $-.427388888354478d+00,-.231301199618376d+00,0.925366575075038d-11,
     $0.231301199635475d+00,0.427388888367565d+00,0.558410493135197d+00,
     $0.604419162326175d+00 /
      data yr16 /
     $0.231301199626926d+00,0.427388888361022d+00,0.558410493131656d+00,
     $0.604419162326175d+00,0.558410493129295d+00,0.427388888356659d+00,
     $0.231301199621226d+00,-.616906576449555d-11,-.231301199632625d+00,
     $-.427388888365384d+00,-.558410493134016d+00,-.604419162326175d+00,
     $-.558410493126934d+00,-.427388888352297d+00,-.231301199615526d+00,
     $0.123382657370052d-10 /
      data zr16 /  16 *
     $0.796666477400000d+00 /
      data wr16 /  16 *
     $0.222381034500000d+00 /
      data xr17 /
     $0.786012298296122d+00,0.601587768385048d+00,0.325576954143464d+00,
     $-.434165916506918d-11,-.325576954151486d+00,-.601587768391188d+00,
     $-.786012298299445d+00,-.850773581010070d+00,-.786012298292799d+00,
     $-.601587768378908d+00,-.325576954135441d+00,0.130253553145749d-10,
     $0.325576954159509d+00,0.601587768397329d+00,0.786012298302768d+00,
     $0.850773581010070d+00 /
      data yr17 /
     $0.325576954147475d+00,0.601587768388118d+00,0.786012298297783d+00,
     $0.850773581010070d+00,0.786012298294460d+00,0.601587768381978d+00,
     $0.325576954139453d+00,-.868350723982203d-11,-.325576954155498d+00,
     $-.601587768394258d+00,-.786012298301106d+00,-.850773581010070d+00,
     $-.786012298291137d+00,-.601587768375838d+00,-.325576954131430d+00,
     $0.173672033893277d-10 /
      data zr17 /  16 *
     $0.525532409900000d+00 /
      data wr17 /  16 *
     $0.313706645900000d+00 /
      data xr18 /
     $0.908203059505102d+00,0.695108528190370d+00,0.376190024632475d+00,
     $-.501659852599236d-11,-.376190024641745d+00,-.695108528197465d+00,
     $-.908203059508942d+00,-.983031907890531d+00,-.908203059501262d+00,
     $-.695108528183276d+00,-.376190024623205d+00,0.150502321318403d-10,
     $0.376190024651014d+00,0.695108528204560d+00,0.908203059512781d+00,
     $0.983031907890531d+00 /
      data yr18 /
     $0.376190024637110d+00,0.695108528193918d+00,0.908203059507022d+00,
     $0.983031907890531d+00,0.908203059503182d+00,0.695108528186823d+00,
     $0.376190024627840d+00,-.100334153289163d-10,-.376190024646380d+00,
     $-.695108528201012d+00,-.908203059510861d+00,-.983031907890531d+00,
     $-.908203059499343d+00,-.695108528179728d+00,-.376190024618570d+00,
     $0.200670489347643d-10 /
      data zr18 /  16 *
     $0.183434642500000d+00 /
      data wr18 /  16 *
     $0.362683783400000d+00 /
      data nang /128/
c
c     data for nang=194
      data xr21/
     $ 1.0000000000000000d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $-1.0000000000000000d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $ 0.7071067811865475d0, 0.7071067811865475d0, 0.0000000000000000d0,
     $-0.7071067811865475d0,-0.7071067811865475d0, 0.7071067811865475d0,
     $ 0.0000000000000000d0,-0.7071067811865475d0, 0.7071067811865475d0,
     $ 0.0000000000000000d0,-0.7071067811865475d0, 0.0000000000000000d0,
     $ 0.5773502691896257d0,-0.5773502691896257d0, 0.5773502691896257d0,
     $-0.5773502691896257d0, 0.5773502691896257d0,-0.5773502691896257d0,
     $ 0.5773502691896257d0,-0.5773502691896257d0, 0.4446933178715401d0,
     $ 0.4446933178715401d0, 0.7774932193150000d0, 0.4446933178715401d0/
      data xr22/
     $ 0.4446933178715401d0, 0.7774932193150000d0, 0.4446933178715401d0,
     $ 0.4446933178715401d0, 0.7774932193150000d0, 0.4446933178715401d0,
     $ 0.4446933178715401d0, 0.7774932193150000d0,-0.4446933178715401d0,
     $-0.4446933178715401d0,-0.7774932193150000d0,-0.4446933178715401d0,
     $-0.4446933178715401d0,-0.7774932193150000d0,-0.4446933178715401d0,
     $-0.4446933178715401d0,-0.7774932193150000d0,-0.4446933178715401d0,
     $-0.4446933178715401d0,-0.7774932193150000d0, 0.2892465627582910d0,
     $ 0.2892465627582910d0, 0.9125090968670000d0, 0.2892465627582910d0,
     $ 0.2892465627582910d0, 0.9125090968670000d0, 0.2892465627582910d0,
     $ 0.2892465627582910d0, 0.9125090968670000d0, 0.2892465627582910d0/
      data xr23/
     $ 0.2892465627582910d0, 0.9125090968670000d0,-0.2892465627582910d0,
     $-0.2892465627582910d0,-0.9125090968670000d0,-0.2892465627582910d0,
     $-0.2892465627582910d0,-0.9125090968670000d0,-0.2892465627582910d0,
     $-0.2892465627582910d0,-0.9125090968670000d0,-0.2892465627582910d0,
     $-0.2892465627582910d0,-0.9125090968670000d0, 0.6712973442694257d0,
     $ 0.6712973442694257d0, 0.3141969941830000d0, 0.6712973442694257d0,
     $ 0.6712973442694257d0, 0.3141969941830000d0, 0.6712973442694257d0,
     $ 0.6712973442694257d0, 0.3141969941830000d0, 0.6712973442694257d0,
     $ 0.6712973442694257d0, 0.3141969941830000d0,-0.6712973442694257d0,
     $-0.6712973442694257d0,-0.3141969941830000d0,-0.6712973442694257d0/
      data xr24/
     $-0.6712973442694257d0,-0.3141969941830000d0,-0.6712973442694257d0,
     $-0.6712973442694257d0,-0.3141969941830000d0,-0.6712973442694257d0,
     $-0.6712973442694257d0,-0.3141969941830000d0, 0.1299335447659648d0,
     $ 0.1299335447659648d0, 0.9829723027070000d0, 0.1299335447659648d0,
     $ 0.1299335447659648d0, 0.9829723027070000d0, 0.1299335447659648d0,
     $ 0.1299335447659648d0, 0.9829723027070000d0, 0.1299335447659648d0,
     $ 0.1299335447659648d0, 0.9829723027070000d0,-0.1299335447659648d0,
     $-0.1299335447659648d0,-0.9829723027070000d0,-0.1299335447659648d0,
     $-0.1299335447659648d0,-0.9829723027070000d0,-0.1299335447659648d0,
     $-0.1299335447659648d0,-0.9829723027070000d0,-0.1299335447659648d0/
      data xr25/
     $-0.1299335447659648d0,-0.9829723027070000d0, 0.9383192181380000d0,
     $ 0.9383192181380000d0,-0.9383192181380000d0,-0.9383192181380000d0,
     $ 0.9383192181380000d0, 0.9383192181380000d0,-0.9383192181380000d0,
     $-0.9383192181380000d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $ 0.0000000000000000d0, 0.0000000000000000d0, 0.3457702197600198d0,
     $ 0.3457702197600198d0,-0.3457702197600198d0,-0.3457702197600198d0,
     $ 0.3457702197600198d0, 0.3457702197600198d0,-0.3457702197600198d0,
     $-0.3457702197600198d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $ 0.0000000000000000d0, 0.0000000000000000d0, 0.8360360154826495d0,
     $ 0.8360360154826495d0, 0.1590417105381236d0, 0.1590417105381236d0/
      data xr26/
     $ 0.5251185724434080d0, 0.5251185724434080d0, 0.8360360154826495d0,
     $ 0.8360360154826495d0, 0.1590417105381236d0, 0.1590417105381236d0,
     $ 0.5251185724434080d0, 0.5251185724434080d0, 0.8360360154826495d0,
     $ 0.8360360154826495d0, 0.1590417105381236d0, 0.1590417105381236d0,
     $ 0.5251185724434080d0, 0.5251185724434080d0, 0.8360360154826495d0,
     $ 0.8360360154826495d0, 0.1590417105381236d0, 0.1590417105381236d0,
     $ 0.5251185724434080d0, 0.5251185724434080d0,-0.8360360154826495d0,
     $-0.8360360154826495d0,-0.1590417105381236d0,-0.1590417105381236d0,
     $-0.5251185724434080d0,-0.5251185724434080d0,-0.8360360154826495d0,
     $-0.8360360154826495d0,-0.1590417105381236d0,-0.1590417105381236d0/
      data xr27/
     $-0.5251185724434080d0,-0.5251185724434080d0,-0.8360360154826495d0,
     $-0.8360360154826495d0,-0.1590417105381236d0,-0.1590417105381236d0,
     $-0.5251185724434080d0,-0.5251185724434080d0,-0.8360360154826495d0,
     $-0.8360360154826495d0,-0.1590417105381236d0,-0.1590417105381236d0,
     $-0.5251185724434080d0,-0.5251185724434080d0, 16*0.d0 /
      data yr21/
     $ 0.0000000000000000d0, 1.0000000000000000d0, 0.0000000000000000d0,
     $ 0.0000000000000000d0,-1.0000000000000000d0, 0.0000000000000000d0,
     $ 0.7071067811865475d0, 0.0000000000000000d0, 0.7071067811865475d0,
     $ 0.7071067811865475d0, 0.0000000000000000d0,-0.7071067811865475d0,
     $-0.7071067811865475d0,-0.7071067811865475d0, 0.0000000000000000d0,
     $ 0.7071067811865475d0, 0.0000000000000000d0,-0.7071067811865475d0,
     $-0.5773502691896257d0, 0.5773502691896257d0,-0.5773502691896257d0,
     $-0.5773502691896257d0,-0.5773502691896257d0, 0.5773502691896257d0,
     $ 0.5773502691896257d0, 0.5773502691896257d0, 0.4446933178715401d0,
     $ 0.7774932193150000d0, 0.4446933178715401d0, 0.4446933178715401d0/
      data yr22/
     $ 0.7774932193150000d0, 0.4446933178715401d0,-0.4446933178715401d0,
     $-0.7774932193150000d0,-0.4446933178715401d0,-0.4446933178715401d0,
     $-0.7774932193150000d0,-0.4446933178715401d0, 0.4446933178715401d0,
     $ 0.7774932193150000d0, 0.4446933178715401d0, 0.4446933178715401d0,
     $ 0.7774932193150000d0, 0.4446933178715401d0,-0.4446933178715401d0,
     $-0.7774932193150000d0,-0.4446933178715401d0,-0.4446933178715401d0,
     $-0.7774932193150000d0,-0.4446933178715401d0, 0.2892465627582910d0,
     $ 0.9125090968670000d0, 0.2892465627582910d0, 0.2892465627582910d0,
     $ 0.9125090968670000d0, 0.2892465627582910d0,-0.2892465627582910d0,
     $-0.9125090968670000d0,-0.2892465627582910d0,-0.2892465627582910d0/
      data yr23/
     $-0.9125090968670000d0,-0.2892465627582910d0, 0.2892465627582910d0,
     $ 0.9125090968670000d0, 0.2892465627582910d0, 0.2892465627582910d0,
     $ 0.9125090968670000d0, 0.2892465627582910d0,-0.2892465627582910d0,
     $-0.9125090968670000d0,-0.2892465627582910d0,-0.2892465627582910d0,
     $-0.9125090968670000d0,-0.2892465627582910d0, 0.6712973442694257d0,
     $ 0.3141969941830000d0, 0.6712973442694257d0, 0.6712973442694257d0,
     $ 0.3141969941830000d0, 0.6712973442694257d0,-0.6712973442694257d0,
     $-0.3141969941830000d0,-0.6712973442694257d0,-0.6712973442694257d0,
     $-0.3141969941830000d0,-0.6712973442694257d0, 0.6712973442694257d0,
     $ 0.3141969941830000d0, 0.6712973442694257d0, 0.6712973442694257d0/
      data yr24/
     $ 0.3141969941830000d0, 0.6712973442694257d0,-0.6712973442694257d0,
     $-0.3141969941830000d0,-0.6712973442694257d0,-0.6712973442694257d0,
     $-0.3141969941830000d0,-0.6712973442694257d0, 0.1299335447659648d0,
     $ 0.9829723027070000d0, 0.1299335447659648d0, 0.1299335447659648d0,
     $ 0.9829723027070000d0, 0.1299335447659648d0,-0.1299335447659648d0,
     $-0.9829723027070000d0,-0.1299335447659648d0,-0.1299335447659648d0,
     $-0.9829723027070000d0,-0.1299335447659648d0, 0.1299335447659648d0,
     $ 0.9829723027070000d0, 0.1299335447659648d0, 0.1299335447659648d0,
     $ 0.9829723027070000d0, 0.1299335447659648d0,-0.1299335447659648d0,
     $-0.9829723027070000d0,-0.1299335447659648d0,-0.1299335447659648d0/
       data yr25/
     $-0.9829723027070000d0,-0.1299335447659648d0, 0.3457702197600198d0,
     $-0.3457702197600198d0, 0.3457702197600198d0,-0.3457702197600198d0,
     $ 0.0000000000000000d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $ 0.0000000000000000d0, 0.9383192181380000d0, 0.9383192181380000d0,
     $-0.9383192181380000d0,-0.9383192181380000d0, 0.9383192181380000d0,
     $-0.9383192181380000d0, 0.9383192181380000d0,-0.9383192181380000d0,
     $ 0.0000000000000000d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $ 0.0000000000000000d0, 0.3457702197600198d0, 0.3457702197600198d0,
     $-0.3457702197600198d0,-0.3457702197600198d0, 0.1590417105381236d0,
     $ 0.5251185724434080d0, 0.8360360154826495d0, 0.5251185724434080d0/
       data yr26/
     $ 0.1590417105381236d0, 0.8360360154826495d0, 0.1590417105381236d0,
     $ 0.5251185724434080d0, 0.8360360154826495d0, 0.5251185724434080d0,
     $ 0.1590417105381236d0, 0.8360360154826495d0,-0.1590417105381236d0,
     $-0.5251185724434080d0,-0.8360360154826495d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.8360360154826495d0,-0.1590417105381236d0,
     $-0.5251185724434080d0,-0.8360360154826495d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.8360360154826495d0, 0.1590417105381236d0,
     $ 0.5251185724434080d0, 0.8360360154826495d0, 0.5251185724434080d0,
     $ 0.1590417105381236d0, 0.8360360154826495d0, 0.1590417105381236d0,
     $ 0.5251185724434080d0, 0.8360360154826495d0, 0.5251185724434080d0/
       data yr27/
     $ 0.1590417105381236d0, 0.8360360154826495d0,-0.1590417105381236d0,
     $-0.5251185724434080d0,-0.8360360154826495d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.8360360154826495d0,-0.1590417105381236d0,
     $-0.5251185724434080d0,-0.8360360154826495d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.8360360154826495d0,16*0.d0/
       data zr21/
     $ 0.0000000000000000d0, 0.0000000000000000d0, 1.0000000000000000d0,
     $ 0.0000000000000000d0, 0.0000000000000000d0,-1.0000000000000000d0,
     $ 0.0000000000000000d0, 0.7071067811865475d0, 0.7071067811865475d0,
     $ 0.0000000000000000d0, 0.7071067811865475d0, 0.0000000000000000d0,
     $ 0.7071067811865475d0, 0.0000000000000000d0,-0.7071067811865475d0,
     $-0.7071067811865475d0,-0.7071067811865475d0,-0.7071067811865475d0,
     $ 0.5773502691896257d0,-0.5773502691896257d0,-0.5773502691896257d0,
     $ 0.5773502691896257d0,-0.5773502691896257d0,-0.5773502691896257d0,
     $-0.5773502691896257d0,-0.5773502691896257d0, 0.7774932193150000d0,
     $ 0.4446933178715401d0, 0.4446933178715401d0,-0.7774932193150000d0/
       data zr22/
     $-0.4446933178715401d0,-0.4446933178715401d0, 0.7774932193150000d0,
     $ 0.4446933178715401d0, 0.4446933178715401d0,-0.7774932193150000d0,
     $-0.4446933178715401d0,-0.4446933178715401d0, 0.7774932193150000d0,
     $ 0.4446933178715401d0, 0.4446933178715401d0,-0.7774932193150000d0,
     $-0.4446933178715401d0,-0.4446933178715401d0, 0.7774932193150000d0,
     $ 0.4446933178715401d0, 0.4446933178715401d0,-0.7774932193150000d0,
     $-0.4446933178715401d0,-0.4446933178715401d0, 0.9125090968670000d0,
     $ 0.2892465627582910d0, 0.2892465627582910d0,-0.9125090968670000d0,
     $-0.2892465627582910d0,-0.2892465627582910d0, 0.9125090968670000d0,
     $ 0.2892465627582910d0, 0.2892465627582910d0,-0.9125090968670000d0/
       data zr23/
     $-0.2892465627582910d0,-0.2892465627582910d0, 0.9125090968670000d0,
     $ 0.2892465627582910d0, 0.2892465627582910d0,-0.9125090968670000d0,
     $-0.2892465627582910d0,-0.2892465627582910d0, 0.9125090968670000d0,
     $ 0.2892465627582910d0, 0.2892465627582910d0,-0.9125090968670000d0,
     $-0.2892465627582910d0,-0.2892465627582910d0, 0.3141969941830000d0,
     $ 0.6712973442694257d0, 0.6712973442694257d0,-0.3141969941830000d0,
     $-0.6712973442694257d0,-0.6712973442694257d0, 0.3141969941830000d0,
     $ 0.6712973442694257d0, 0.6712973442694257d0,-0.3141969941830000d0,
     $-0.6712973442694257d0,-0.6712973442694257d0, 0.3141969941830000d0,
     $ 0.6712973442694257d0, 0.6712973442694257d0,-0.3141969941830000d0/
       data zr24/
     $-0.6712973442694257d0,-0.6712973442694257d0, 0.3141969941830000d0,
     $ 0.6712973442694257d0, 0.6712973442694257d0,-0.3141969941830000d0,
     $-0.6712973442694257d0,-0.6712973442694257d0, 0.9829723027070000d0,
     $ 0.1299335447659648d0, 0.1299335447659648d0,-0.9829723027070000d0,
     $-0.1299335447659648d0,-0.1299335447659648d0, 0.9829723027070000d0,
     $ 0.1299335447659648d0, 0.1299335447659648d0,-0.9829723027070000d0,
     $-0.1299335447659648d0,-0.1299335447659648d0, 0.9829723027070000d0,
     $ 0.1299335447659648d0, 0.1299335447659648d0,-0.9829723027070000d0,
     $-0.1299335447659648d0,-0.1299335447659648d0, 0.9829723027070000d0,
     $ 0.1299335447659648d0, 0.1299335447659648d0,-0.9829723027070000d0/
       data zr25/
     $-0.1299335447659648d0,-0.1299335447659648d0, 0.0000000000000000d0,
     $ 0.0000000000000000d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $ 0.3457702197600198d0,-0.3457702197600198d0, 0.3457702197600198d0,
     $-0.3457702197600198d0, 0.3457702197600198d0,-0.3457702197600198d0,
     $ 0.3457702197600198d0,-0.3457702197600198d0, 0.0000000000000000d0,
     $ 0.0000000000000000d0, 0.0000000000000000d0, 0.0000000000000000d0,
     $ 0.9383192181380000d0,-0.9383192181380000d0, 0.9383192181380000d0,
     $-0.9383192181380000d0, 0.9383192181380000d0,-0.9383192181380000d0,
     $ 0.9383192181380000d0,-0.9383192181380000d0, 0.5251185724434080d0,
     $ 0.1590417105381236d0, 0.5251185724434080d0, 0.8360360154826495d0/
      data zr26/
     $ 0.8360360154826495d0, 0.1590417105381236d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.5251185724434080d0,-0.8360360154826495d0,
     $-0.8360360154826495d0,-0.1590417105381236d0, 0.5251185724434080d0,
     $ 0.1590417105381236d0, 0.5251185724434080d0, 0.8360360154826495d0,
     $ 0.8360360154826495d0, 0.1590417105381236d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.5251185724434080d0,-0.8360360154826495d0,
     $-0.8360360154826495d0,-0.1590417105381236d0, 0.5251185724434080d0,
     $ 0.1590417105381236d0, 0.5251185724434080d0, 0.8360360154826495d0,
     $ 0.8360360154826495d0, 0.1590417105381236d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.5251185724434080d0,-0.8360360154826495d0/
      data zr27/
     $-0.8360360154826495d0,-0.1590417105381236d0, 0.5251185724434080d0,
     $ 0.1590417105381236d0, 0.5251185724434080d0, 0.8360360154826495d0,
     $ 0.8360360154826495d0, 0.1590417105381236d0,-0.5251185724434080d0,
     $-0.1590417105381236d0,-0.5251185724434080d0,-0.8360360154826495d0,
     $-0.8360360154826495d0,-0.1590417105381236d0,16*0.d0/
      data wr21/
     $ 0.0017823404472400d0, 0.0017823404472400d0, 0.0017823404472400d0,
     $ 0.0017823404472400d0, 0.0017823404472400d0, 0.0017823404472400d0,
     $ 0.0057169059499800d0, 0.0057169059499800d0, 0.0057169059499800d0,
     $ 0.0057169059499800d0, 0.0057169059499800d0, 0.0057169059499800d0,
     $ 0.0057169059499800d0, 0.0057169059499800d0, 0.0057169059499800d0,
     $ 0.0057169059499800d0, 0.0057169059499800d0, 0.0057169059499800d0,
     $ 0.0055733831788400d0, 0.0055733831788400d0, 0.0055733831788400d0,
     $ 0.0055733831788400d0, 0.0055733831788400d0, 0.0055733831788400d0,
     $ 0.0055733831788400d0, 0.0055733831788400d0, 0.0055187714672700d0,
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0055187714672700d0/
      data wr22/
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0055187714672700d0,
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0055187714672700d0,
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0055187714672700d0,
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0055187714672700d0,
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0055187714672700d0,
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0055187714672700d0,
     $ 0.0055187714672700d0, 0.0055187714672700d0, 0.0051582377118100d0,
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0051582377118100d0,
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0051582377118100d0,
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0051582377118100d0/
      data wr23/
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0051582377118100d0,
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0051582377118100d0,
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0051582377118100d0,
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0051582377118100d0,
     $ 0.0051582377118100d0, 0.0051582377118100d0, 0.0056087040825900d0,
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0056087040825900d0,
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0056087040825900d0,
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0056087040825900d0,
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0056087040825900d0,
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0056087040825900d0/
      data wr24/
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0056087040825900d0,
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0056087040825900d0,
     $ 0.0056087040825900d0, 0.0056087040825900d0, 0.0041067770281700d0,
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0041067770281700d0,
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0041067770281700d0,
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0041067770281700d0,
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0041067770281700d0,
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0041067770281700d0,
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0041067770281700d0,
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0041067770281700d0/
      data wr25/
     $ 0.0041067770281700d0, 0.0041067770281700d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0050518460646200d0,
     $ 0.0050518460646200d0, 0.0050518460646200d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0/
c
      data wr26/
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0/
c
      data wr27/
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 0.0055302489162300d0,
     $ 0.0055302489162300d0, 0.0055302489162300d0, 16*0.d0/
      data nangy /194/
c
c
      data xr31/
     $ 0.0000000000000000d0,-0.8506508083080166d0,-0.5257311121903647d0,
     $ 0.0000000000000000d0, 0.8506508083080166d0,-0.5257311121903647d0,
     $ 0.0000000000000000d0,-0.8506508083080166d0, 0.5257311121903647d0,
     $ 0.0000000000000000d0, 0.8506508083080166d0, 0.5257311121903647d0,
     $-0.1552405999750772d0, 0.1511082749757406d0, 0.9762513228432696d0,
     $ 0.9762513228432696d0, 0.1511082749757406d0,-0.9762513228432696d0/
c
      data xr32/
     $ 0.1552405999750772d0, 0.1552405999750772d0,-0.9762513228432696d0,
     $-0.1552405999750772d0,-0.1511082749757406d0,-0.1511082749757406d0,
     $-0.2570493870082321d0,-0.3158383530101148d0, 0.9133300320292496d0,
     $ 0.9133300320292496d0,-0.3158383530101148d0,-0.9133300320292496d0,
     $ 0.2570493870082321d0, 0.2570493870082321d0,-0.9133300320292496d0,
     $-0.2570493870082321d0, 0.3158383530101148d0, 0.3158383530101148d0/
c
      data xr33/
     $-0.6662777899289462d0,-0.3463071119630688d0, 0.6604129699295716d0,
     $ 0.6604129699295716d0,-0.3463071119630688d0,-0.6604129699295716d0,
     $ 0.6662777899289462d0, 0.6662777899289462d0,-0.6604129699295716d0,
     $-0.6662777899289462d0, 0.3463071119630688d0, 0.3463071119630688d0,
     $-0.8173860649297367d0, 0.1018087869912484d0, 0.5670229199512581d0,
     $ 0.5670229199512581d0, 0.1018087869912484d0,-0.5670229199512581d0/
c
      data xr34/
     $ 0.8173860649297367d0, 0.8173860649297367d0,-0.5670229199512581d0,
     $-0.8173860649297367d0,-0.1018087869912484d0,-0.1018087869912484d0,
     $-0.5015477119803060d0, 0.4092284029839311d0, 0.7622217569700703d0,
     $ 0.7622217569700703d0, 0.4092284029839311d0,-0.7622217569700703d0,
     $ 0.5015477119803060d0, 0.5015477119803060d0,-0.7622217569700703d0,
     $-0.5015477119803060d0,-0.4092284029839311d0,-0.4092284029839311d0/
c
      data yr31/
     $-0.5257311121903647d0, 0.0000000000000000d0,-0.8506508083080166d0,
     $-0.5257311121903647d0, 0.0000000000000000d0, 0.8506508083080166d0,
     $ 0.5257311121903647d0, 0.0000000000000000d0,-0.8506508083080166d0,
     $ 0.5257311121903647d0, 0.0000000000000000d0, 0.8506508083080166d0,
     $ 0.9762513228432696d0,-0.1552405999750772d0, 0.1511082749757406d0,
     $-0.1511082749757406d0, 0.1552405999750772d0, 0.1511082749757406d0/
c
      data yr32/
     $-0.9762513228432696d0, 0.9762513228432696d0,-0.1511082749757406d0,
     $-0.9762513228432696d0,-0.1552405999750772d0, 0.1552405999750772d0,
     $ 0.9133300320292496d0,-0.2570493870082321d0,-0.3158383530101148d0,
     $ 0.3158383530101148d0, 0.2570493870082321d0,-0.3158383530101148d0,
     $-0.9133300320292496d0, 0.9133300320292496d0, 0.3158383530101148d0,
     $-0.9133300320292496d0,-0.2570493870082321d0, 0.2570493870082321d0/
c
      data yr33/
     $ 0.6604129699295716d0,-0.6662777899289462d0,-0.3463071119630688d0,
     $ 0.3463071119630688d0, 0.6662777899289462d0,-0.3463071119630688d0,
     $-0.6604129699295716d0, 0.6604129699295716d0, 0.3463071119630688d0,
     $-0.6604129699295716d0,-0.6662777899289462d0, 0.6662777899289462d0,
     $ 0.5670229199512581d0,-0.8173860649297367d0, 0.1018087869912484d0,
     $-0.1018087869912484d0, 0.8173860649297367d0, 0.1018087869912484d0/
c
      data yr34/
     $-0.5670229199512581d0, 0.5670229199512581d0,-0.1018087869912484d0,
     $-0.5670229199512581d0,-0.8173860649297367d0, 0.8173860649297367d0,
     $ 0.7622217569700703d0,-0.5015477119803060d0, 0.4092284029839311d0,
     $-0.4092284029839311d0, 0.5015477119803060d0, 0.4092284029839311d0,
     $-0.7622217569700703d0, 0.7622217569700703d0,-0.4092284029839311d0,
     $-0.7622217569700703d0,-0.5015477119803060d0, 0.5015477119803060d0/
c
      data zr31/
     $-0.8506508083080166d0,-0.5257311121903647d0, 0.0000000000000000d0,
     $ 0.8506508083080166d0,-0.5257311121903647d0, 0.0000000000000000d0,
     $-0.8506508083080166d0, 0.5257311121903647d0, 0.0000000000000000d0,
     $ 0.8506508083080166d0, 0.5257311121903647d0, 0.0000000000000000d0,
     $ 0.1511082749757406d0, 0.9762513228432696d0,-0.1552405999750772d0,
     $ 0.1552405999750772d0,-0.9762513228432696d0, 0.1552405999750772d0/
c
      data zr32/
     $ 0.1511082749757406d0,-0.1511082749757406d0,-0.1552405999750772d0,
     $-0.1511082749757406d0,-0.9762513228432696d0, 0.9762513228432696d0,
     $-0.3158383530101148d0, 0.9133300320292496d0,-0.2570493870082321d0,
     $ 0.2570493870082321d0,-0.9133300320292496d0, 0.2570493870082321d0,
     $-0.3158383530101148d0, 0.3158383530101148d0,-0.2570493870082321d0,
     $ 0.3158383530101148d0,-0.9133300320292496d0, 0.9133300320292496d0/
c
      data zr33/
     $-0.3463071119630688d0, 0.6604129699295716d0,-0.6662777899289462d0,
     $ 0.6662777899289462d0,-0.6604129699295716d0, 0.6662777899289462d0,
     $-0.3463071119630688d0, 0.3463071119630688d0,-0.6662777899289462d0,
     $ 0.3463071119630688d0,-0.6604129699295716d0, 0.6604129699295716d0,
     $ 0.1018087869912484d0, 0.5670229199512581d0,-0.8173860649297367d0,
     $ 0.8173860649297367d0,-0.5670229199512581d0, 0.8173860649297367d0/
c
      data zr34/
     $ 0.1018087869912484d0,-0.1018087869912484d0,-0.8173860649297367d0,
     $-0.1018087869912484d0,-0.5670229199512581d0, 0.5670229199512581d0,
     $ 0.4092284029839311d0, 0.7622217569700703d0,-0.5015477119803060d0,
     $ 0.5015477119803060d0,-0.7622217569700703d0, 0.5015477119803060d0,
     $ 0.4092284029839311d0,-0.4092284029839311d0,-0.5015477119803060d0,
     $-0.4092284029839311d0,-0.7622217569700703d0, 0.7622217569700703d0/
c
      data wr31/
     $ 0.1558329687500000d0, 0.1558329687500000d0, 0.1558329687500000d0,
     $ 0.1558329687500000d0, 0.1558329687500000d0, 0.1558329687500000d0,
     $ 0.1558329687500000d0, 0.1558329687500000d0, 0.1558329687500000d0,
     $ 0.1558329687500000d0, 0.1558329687500000d0, 0.1558329687500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0/
c
      data wr32/
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0/
c
      data wr33/
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0/
c
      data wr34/
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0,
     $ 0.1782729162500000d0, 0.1782729162500000d0, 0.1782729162500000d0/
      data nangz/72/
c
c
c     data for bragg-slater atomic radii
      data rm /
     $   0.250d0, 0.250d0, 1.450d0, 1.050d0, 0.850d0,
     $   0.700d0, 0.650d0, 0.600d0, 0.500d0, 0.500d0,
     $   1.800d0, 1.500d0, 1.250d0, 1.100d0, 1.000d0,
     $   1.000d0, 1.000d0, 1.000d0, 2.200d0, 1.800d0,
     $   1.600d0, 1.400d0, 1.350d0, 1.400d0, 1.400d0,
     $   1.400d0, 1.350d0, 1.350d0, 1.350d0, 1.350d0,
     $   1.300d0, 1.250d0, 1.150d0, 1.150d0, 1.150d0,
     $   1.150d0, 64* 0.00d0 /
c
c      values for constants characteristic of the colle-salvetti
c      functional
c      ......given by lee et al ( phys.rev.b 37,785(1988))
       data  acost,bcost,ccost,dcost/
     $ 0.04918d0, 0.1320d0, 0.2533d0, 0.3490d0 /
c
c      data optimized to reproduce the corr. energy of b-cl (clementi)
c      data  acost,bcost,ccost,dcost/
c    *  0.0492510e0, 0.1583655e0, 0.4671982e0, 0.3520999e0 /
      end
       block data datrad
       implicit REAL  (a-h,o-z)
INCLUDE(common/radyyy)
       dimension rcg20(20), wcg20(20), rcg25(25),wcg25(25) ,
     $           rcg30(30), wcg30(30), rcg35(35),wcg35(35) ,
     $           rcg40(40), wcg40(40), rcg45(45),wcg45(45) ,
     $           rcg50(50), wcg50(50)
       equivalence (rrr(  1),rcg20(1)), (www(  1),wcg20(1))
     $            ,(rrr( 21),rcg25(1)), (www( 21),wcg25(1))
     $            ,(rrr( 46),rcg30(1)), (www( 46),wcg30(1))
     $            ,(rrr( 76),rcg35(1)), (www( 76),wcg35(1))
     $            ,(rrr(111),rcg40(1)), (www(111),wcg40(1))
     $            ,(rrr(151),rcg45(1)), (www(151),wcg45(1))
     $            ,(rrr(196),rcg50(1)), (www(196),wcg50(1))
c
      data rcg20/
     $ 0.714255698384606d+03,0.787699822409711d+02,0.279325684638375d+02
     $,0.139282032302755d+02,0.816722551275952d+01,0.525337560675948d+01
     $,0.358001343302228d+01,0.253284323061569d+01,0.183589461054094d+01
     $,0.135029299400440d+01,0.100000000000000d+01,0.740580010738573d+00
     $,0.544693575686981d+00,0.394813223302778d+00,0.279328560830508d+00
     $,0.190353798177558d+00,0.122440600965128d+00,0.717967697244908d-01
     $,0.358005029610734d-01,0.126951913857341d-01 /
      data wcg20/
     $ 0.145890223358693d+10,0.657161242725743d+06,0.178482132899819d+05
     $,0.161687279758245d+04,0.261429662165263d+03,0.591754032499378d+02
     $,0.166153299610861d+02,0.539604694575856d+01,0.193749251112589d+01
     $,0.744942273049139d+00,0.299199300341885d+00,0.122900750181082d+00
     $,0.506003535127531d-01,0.204374100523460d-01,0.789225361966139d-02
     $,0.281520812371744d-02,0.880861395214830d-03,0.221465093503766d-03
     $,0.375776412332138d-04,0.275110684136719d-05 /
      data rcg25/
     $ 0.109522331645103d+04,0.121099428467608d+03,0.431704565829968d+02
     $,0.217014359114563d+02,0.128678244629950d+02,0.839776670403083d+01
     $,0.582842712474619d+01,0.421810195486536d+01,0.314368487680979d+01
     $,0.239220393267843d+01,0.184698746517791d+01,0.143978321582655d+01
     $,0.112851663623416d+01,0.886118970595759d+00,0.694549005022206d+00
     $,0.541422190920865d+00,0.418024561509834d+00,0.318098040734541d+00
     $,0.237073454055929d+00,0.171572875253810d+00,0.119079278484839d+00
     $,0.777132142947534d-01,0.460799001540766d-01,0.231639894305372d-01
     $,0.825767728761399d-02 /
      data wcg25/
     $ 0.525814141984223d+10,0.238092321448810d+07,0.653544280076301d+05
     $,0.601798400788526d+04,0.995285506974273d+03,0.232065562570321d+03
     $,0.676667986446346d+02,0.230399624550947d+02,0.877325514281304d+01
     $,0.362788889360855d+01,0.159485773805932d+01,0.733281165666584d+00
     $,0.347955325549283d+00,0.168451814624257d+00,0.823166885597531d-01
     $,0.401733697123925d-01,0.193581913315501d-01,0.908922228488237d-02
     $,0.409052762912588d-02,0.172610577747731d-02,0.661649312004197d-03
     $,0.219238545987190d-03,0.576129622483404d-04,0.100961354066613d-04
     $,0.754905915600020d-06 /
      data rcg30/
     $ 0.155724789581452d+04,0.172435332115306d+03,0.616509866580516d+02
     $,0.311296145391781d+02,0.185703409094618d+02,0.122139023395867d+02
     $,0.855912077656334d+01,0.626725139164529d+01,0.473678181119148d+01
     $,0.366492121745113d+01,0.288577351068834d+01,0.230226919039101d+01
     $,0.185454572201164d+01,0.150406447252609d+01,0.122511071752862d+01
     $,0.100000000000000d+01,0.816252756336398d+00,0.664865116001636d+00
     $,0.539215608507775d+00,0.434354073004887d+00,0.346527541505318d+00
     $,0.272857161359522d+00,0.211113798325548d+00,0.159559580031060d+00
     $,0.116834430323522d+00,0.818739148387390d-01,0.538493076069750d-01
     $,0.321237514438688d-01,0.162203405688626d-01,0.579927551814791d-02
     $ /
      data wcg30/
     $ 0.151119013467888d+11,0.686264288320752d+07,0.189481219960789d+06
     $,0.176046766189088d+05,0.294738087445270d+04,0.698160669461339d+03
     $,0.207624698307803d+03,0.724187711616186d+02,0.283899718867290d+02
     $,0.121560954301743d+02,0.557084748367913d+01,0.269147844293298d+01
     $,0.135493681989772d+01,0.704044025916961d+00,0.374608952794104d+00
     $,0.202683397005793d+00,0.110796519340320d+00,0.608136541829865d-01
     $,0.333037988880673d-01,0.180740007356895d-01,0.964601234000551d-02
     $,0.501656265626980d-02,0.251341776228304d-02,0.119505655545342d-02
     $,0.528085309497826d-03,0.210294890413230d-03,0.718649292226519d-04
     $,0.193457509880517d-04,0.345084921987074d-05,0.261056104246781d-06
     $ /
      data rcg35/
     $ 0.210032942907422d+04,0.232777626218406d+03,0.833739706689609d+02
     $,0.422123646201505d+02,0.252741423690882d+02,0.167008120004519d+02
     $,0.117706944897175d+02,0.867835629580792d+01,0.661259030993665d+01
     $,0.516504201460888d+01,0.411197041470786d+01,0.332245149578159d+01
     $,0.271573589809128d+01,0.223982880884355d+01,0.186002657905958d+01
     $,0.155245164964479d+01,0.130024180384071d+01,0.109121763195340d+01
     $,0.916407479789246d+00,0.769087716643286d+00,0.644142444132675d+00
     $,0.537626726014632d+00,0.446462692171690d+00,0.368224318389294d+00
     $,0.300982573039717d+00,0.243192411215596d+00,0.193609267295713d+00
     $,0.151226668087590d+00,0.115229193860484d+00,0.849567543252075d-01
     $,0.598773281187130d-01,0.395661298965801d-01,0.236897413589250d-01
     $,0.119941510758859d-01,0.429594551781252d-02
     $ /
      data wcg35/
     $ 0.370731986914909d+11,0.168656624525836d+08,0.467339051202883d+06
     $,0.436570720906590d+05,0.736320665692848d+04,0.176069661589507d+04
     $,0.529745293084210d+03,0.187388385317545d+03,0.746979822282879d+02
     $,0.326188059462382d+02,0.152953935848633d+02,0.758969151172124d+01
     $,0.394104181520617d+01,0.212278739667851d+01,0.117764750553867d+01
     $,0.668882916352903d+00,0.386973455873360d+00,0.226999573234847d+00
     $,0.134448757283397d+00,0.800822795451237d-01,0.477795004733000d-01
     $,0.284380894242088d-01,0.168119288304763d-01,0.982394323670462d-02
     $,0.564250857146016d-02,0.316417699815358d-02,0.171800691470624d-02
     $,0.893468349375883d-03,0.438649673582810d-03,0.199184060081580d-03
     $,0.811444845906069d-04,0.282493477211387d-04,0.771643178060878d-05
     $,0.139139090894133d-05,0.106012235723333d-06
     $ /
      data rcg40/
     $ 0.272446791304272d+04,0.302126281981900d+03,0.108339328025426d+03
     $,0.549495264041344d+02,0.329789607593551d+02,0.218580876084322d+02
     $,0.154625652791862d+02,0.114506197628591d+02,0.877005545650240d+01
     $,0.689120308697678d+01,0.552384876142600d+01,0.449816755091445d+01
     $,0.370941341813976d+01,0.309013579033777d+01,0.259531066563844d+01
     $,0.219395484939095d+01,0.186418301324137d+01,0.159018207433531d+01
     $,0.136029776425728d+01,0.116578957366514d+01,0.100000000000000d+01
     $,0.857787736817794d+00,0.735133164425949d+00,0.628858805629536d+00
     $,0.536428018545905d+00,0.455797894053109d+00,0.385310326520776d+00
     $,0.323610374381216d+00,0.269584402512215d+00,0.222312750399150d+00
     $,0.181033196814362d+00,0.145112542378824d+00,0.114024364493450d+00
     $,0.873315174820116d-01,0.646723219559228d-01,0.457496565076549d-01
     $,0.303223624084738d-01,0.181985189944196d-01,0.923025846870044d-02
     $,0.330987424675591d-02
     $ /
      data wcg40/
     $ 0.809117013003662d+11,0.368519840215066d+08,0.102354693075183d+07
     $,0.959560395865791d+05,0.162617965271085d+05,0.391233752032175d+04
     $,0.118595276337375d+04,0.423281677508658d+03,0.170517475296312d+03
     $,0.753783902952519d+02,0.358487774107137d+02,0.180789438999930d+02
     $,0.956303905421629d+01,0.526074986678060d+01,0.298934347217998d+01
     $,0.174487372484134d+01,0.104132943921931d+01,0.632868446385878d+00
     $,0.390317273709664d+00,0.243518910321566d+00,0.153248422126331d+00
     $,0.970089246956540d-01,0.616047027017465d-01,0.391410365169586d-01
     $,0.248117198380877d-01,0.156458041085160d-01,0.978227142362401d-02
     $,0.604202152531360d-02,0.367083190475479d-02,0.218252530249004d-02
     $,0.126189631594469d-02,0.703844246828543d-03,0.374761403096579d-03
     $,0.187782669699248d-03,0.867717017063425d-04,0.358726401343478d-04
     $,0.126399899055381d-04,0.348568865346543d-05,0.632981380285259d-06
     $,0.484540225269556d-07
     $ /
      data rcg45/
     $ 0.342966334616367d+04,0.380481285360375d+03,0.136547019493664d+03
     $,0.693410223452537d+02,0.416846664505439d+02,0.276855327928337d+02
     $,0.196344542343340d+02,0.145836631200877d+02,0.112086798580497d+02
     $,0.884276727597047d+01,0.712060809410799d+01,0.582842712474619d+01
     $,0.483436833016065d+01,0.405352171610685d+01,0.342920670612342d+01
     $,0.292241630913059d+01,0.250559501835011d+01,0.215883017691541d+01
     $,0.186744333165148d+01,0.162042291217908d+01,0.140937841400301d+01
     $,0.122782681302416d+01,0.107069585535945d+01,0.933972047238644d+00
     $,0.814447110449544d+00,0.709532649332789d+00,0.617122846439663d+00
     $,0.535491483490235d+00,0.463213832515915d+00,0.399106796060955d+00
     $,0.342182596256280d+00,0.291612633969930d+00,0.246699060726986d+00
     $,0.206852256945587d+00,0.171572875253810d+00,0.140437443935085d+00
     $,0.113086771232510d+00,0.892165725727132d-01,0.685698779357150d-01
     $,0.509308783460526d-01,0.361199478255606d-01,0.239896366014212d-01
     $,0.144214775925993d-01,0.732348464073509d-02,0.262825016229864d-02
     $ /
      data wcg45/
     $ 0.161398269359643d+12,0.735696226569871d+08,0.204667454158909d+07
     $,0.192342970254105d+06,0.327042926181197d+05,0.790109304043588d+04
     $,0.240731051368499d+04,0.864426657580694d+03,0.350708998535903d+03
     $,0.156307474525977d+03,0.750366266601937d+02,0.382464514078369d+02
     $,0.204755334204994d+02,0.114174058066457d+02,0.658721973380017d+01
     $,0.391111813712903d+01,0.237920013788593d+01,0.147728578764000d+01
     $,0.933266043413032d+00,0.598183414503455d+00,0.388030706991859d+00
     $,0.254165295602921d+00,0.167754299205007d+00,0.111346592207320d+00
     $,0.741811516645491d-01,0.495108521981772d-01,0.330418317564663d-01
     $,0.220049746917665d-01,0.145933043073635d-01,0.961536367486797d-02
     $,0.627839212961366d-02,0.405079406082969d-02,0.257378587558615d-02
     $,0.160397209155274d-02,0.975625004661091d-03,0.575666291774087d-03
     $,0.326926837825202d-03,0.176856130618395d-03,0.898521367773354d-04
     $,0.420164260946720d-04,0.175456661595479d-04,0.623371259820564d-05
     $,0.173035365810910d-05,0.315758781777609d-06,0.242492732840771d-07
     $ /
      data rcg50/
     $ 0.421591572760404d+04,0.467842628839062d+03,0.167997024108828d+03
     $,0.853868110849429d+02,0.513911904804106d+02,0.341830434159276d+02
     $,0.242862140067886d+02,0.180772872007421d+02,0.139282032302755d+02
     $,0.110194030584977d+02,0.890183456276682d+01,0.731272182370276d+01
     $,0.608998416993318d+01,0.512924700837785d+01,0.436083521703430d+01
     $,0.373679783200222d+01,0.322325978079893d+01,0.279574026081426d+01
     $,0.243619198869013d+01,0.213107460854826d+01,0.187006913236608d+01
     $,0.164520075709703d+01,0.145022826161168d+01,0.128021126466968d+01
     $,0.113119851152051d+01,0.100000000000000d+01,0.884018136353308d+00
     $,0.781121075557804d+00,0.689546622742459d+00,0.607828555686120d+00
     $,0.534739589404785d+00,0.469246827862692d+00,0.410476680262655d+00
     $,0.357687019075495d+00,0.310244928428368d+00,0.267608804371466d+00
     $,0.229313869988437d+00,0.194960390553750d+00,0.164204039303927d+00
     $,0.136747988520320d+00,0.112336394587992d+00,0.907490174096902d-01
     $,0.717967697244909d-01,0.553180346639041d-01,0.411756233277232d-01
     $,0.292542705408744d-01,0.194585879535362d-01,0.117114105479967d-01
     $,0.595248639256971d-02,0.213747088947727d-02
     $ /
      data wcg50/
     $ 0.299781219128646d+12,0.136727624104833d+09,0.380813841645097d+07
     $,0.358512353617340d+06,0.611025956079530d+05,0.148060740588025d+05
     $,0.452754786047581d+04,0.163278671891634d+04,0.665771151945716d+03
     $,0.298440505672411d+03,0.144209595816636d+03,0.740492351417559d+02
     $,0.399728737113762d+02,0.224968055693830d+02,0.131140352070461d+02
     $,0.787614225734170d+01,0.485250248067150d+01,0.305575291455502d+01
     $,0.196081172105989d+01,0.127870319191935d+01,0.845505055758133d+00
     $,0.565699228776306d+00,0.382276104793493d+00,0.260470710145943d+00
     $,0.178669599225429d+00,0.123199711905482d+00,0.852742116899405d-01
     $,0.591655666829181d-01,0.410921596230172d-01,0.285280562733088d-01
     $,0.197683416545753d-01,0.136514197977986d-01,0.937922231647145d-02
     $,0.639937132031027d-02,0.432706990097955d-02,0.289278354096107d-02
     $,0.190685771176419d-02,0.123537603426342d-02,0.783553020320868d-03
     $,0.484223941085306d-03,0.289812455593996d-03,0.166689926651967d-03
     $,0.911915090897863d-04,0.467875077324496d-04,0.220650107854766d-04
     $,0.928058937961719d-05,0.331686342707456d-05,0.925037542354012d-06
     $,0.169396016464987d-06,0.130393973417861d-07
     $ /
       end
      function  ecrho(a, x0, b, c, rho)
      implicit REAL  (a-h,o-z)
      data aa13   /0.333333333333333d0/
      data aa12   /0.500000000000000d0/
c     data aa1    /1.000000000000000d0/
      data aa2    /2.000000000000000d0/
      data aa4    /4.000000000000000d0/
      data a34pi  /0.238732415000000d0/
c
      rs    = (a34pi/rho)**aa13
      x     =  dsqrt(rs)
      xofx  = x * x + b * x + c
      xofx0 = x0*x0 + b * x0+ c
      q     =  dsqrt(aa4*c-b*b)
      tangm1=  datan( q/(x+x+b) )
      ec1   = dlog(x*x/xofx) + aa2 * b * tangm1 / q
      ec2   = dlog((x-x0)**aa2/xofx ) + aa2 * (b+x0+x0) * tangm1 / q
      ec2   = ec2 * (b*x0/xofx0)
      ecrho = aa12 * a * (ec1-ec2)
      return
      end
       function ecwvn (rhoa, rhob )
       implicit REAL  (a-h, o-z)
      data    ap ,  x0p ,  bp ,  cp /
     $ 0.0621814000d0, -0.1049800000d0, 3.7274400000d0, 12.9352000000d0/
      data    af ,  x0f ,  bf ,  cf /
     $ 0.0310907000d0, -0.3250000000d0, 7.0604200000d0, 18.0578000000d0/
      data    aal,  x0al,  bal,  cal/
     $-0.0337737280d0, -0.0047584000d0, 1.1310700000d0, 13.0045000000d0/
      data zero   /0.000000000000000d0/
      data aa43   /1.333333333333333d0/
      data aa1    /1.000000000000000d0/
      data aa2    /2.000000000000000d0/
c     data aa13   /0.333333333333333d0/
c     data aa49   /0.444444444444444d0/
c     data aa4    /4.000000000000000d0/
c     data a34pi  /0.238732415000000d0/
      data cost   /1.923661051000000d0/
      data cost89 /1.709920934000000d0/
c
          ecwvn = zero
          rho   = rhoa + rhob
          if(rho.le.1.d-20) return
          csi   = (rhoa-rhob)/rho
          fcsi  = (   (aa1+csi)**aa43 +(aa1-csi)**aa43-aa2)* cost
          f2zer = cost89
          csi2  = csi * csi
          csi4  = csi2* csi2
                  ecf = ecrho(af , x0f , bf , cf , rho)
                  ecp = ecrho(ap , x0p , bp , cp , rho)
                  ecal= ecrho(aal, x0al, bal, cal, rho)
          alcf2 = ecal / f2zer
          ecwvn = ecp +  alcf2 * fcsi + (ecf-ecp-alcf2)*csi4*fcsi
      return
      end
      subroutine gaupt (xp,yp,zp)
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/dnfnw)
c
c     data zero,pt5 /0.0d+00,0.5d+00 / 
c
      data one,two,three,five,seven /1.0d+00, + 2.0d+00,3.0d+00,
     +                               5.0d+00,7.0d+00/
      data sq3/1.732050808d0/
c
c     data ncall/0/
c
c     ----- calculate value, derivatives and del2
c           of contracted function at the point (xp, yp, zp)
c
c     ----- ishell
c
c
      do 720 ii = 1,nshell
      i = katom(ii)
      xi = c(1,i)
      yi = c(2,i)
      zi = c(3,i)
      i1 = kstart(ii)
      i2 = i1+kng(ii)-1
c     lit = ktype(ii)
      mini = kmin(ii)
      maxi = kmax(ii)
      loci = kloc(ii)-mini
c
      dx  = xp - xi
      dy  = yp - yi
      dz  = zp - zi
      dx2 = dx * dx
      dy2 = dy * dy
      dz2 = dz * dz
      r2  = dx2 + dy2 + dz2
c
c     ----- i primitive
c
      do 660 ig = i1,i2
      ai = ex(ig)
      argai=ai*r2
      if(argai.gt.60) goto 660
      expon =  dexp(-argai)
      csi = cs(ig)
      cpi = cp(ig)
      cdi = cd(ig)
              ee    =two*ai
              eer2  =ee*r2
              expee =ee*expon
              expons=expon  *  csi
              expees=expee  *  csi
              exponp=expon  *  cpi
              expeep=expee  *  cpi
              expond=expon  *  cdi
c
              do 420 i=mini,maxi
              llii=loci+i
              goto(311,312,313,314,315,316,317,318,319,320),i
c
c    s
c
  311 continue
      vg(llii) = vg(llii) +    expons
      gxp(llii) = gxp(llii)     -expees*dx
      gyp(llii) = gyp(llii)     -expees*dy
      gzp(llii) = gzp(llii)     -expees*dz
      d2(llii) = d2(llii)     -expees*(three-eer2)
      go to 420
c
c    x
c
  312 continue
      q2=  -expeep*dx
      bf=   exponp*dx
      vg(llii) = vg(llii) +    bf
      gxp(llii) = gxp(llii) +    exponp*(one-ee*dx*dx)
      gyp(llii) = gyp(llii) +    q2*dy
      gzp(llii) = gzp(llii) +    q2*dz
      d2(llii) = d2(llii)     -expeep*(five-eer2)*dx
      go to 420
c
c    y
c
  313 continue
      q2=  -expeep*dy
      bf=   exponp*dy
      vg(llii) = vg(llii) +    bf
      gxp(llii) = gxp(llii) +    q2*dx
      gyp(llii) = gyp(llii) +    exponp*(one-ee*dy*dy)
      gzp(llii) = gzp(llii) +    q2*dz
      d2(llii) = d2(llii)     -expeep*(five-eer2)*dy
      go to 420
c
c    z
c
  314 continue
      q2=  -expeep*dz
      bf=   exponp*dz
      vg(llii) = vg(llii) +    bf
      gxp(llii) = gxp(llii) +    q2*dx
      gyp(llii) = gyp(llii) +    q2*dy
      gzp(llii) = gzp(llii) +    exponp*(one-ee*dz*dz)
      d2(llii) = d2(llii)     -expeep*(five-eer2)*dz
      go to 420
c
c    xx
c
  315 continue
      bf=   expond*dx*dx
      vg(llii) = vg(llii) +    bf
      q2=  -bf*ee
      q3=   expond*two
      gxp(llii) = gxp(llii) +    dx*(q2+q3)
      gyp(llii) = gyp(llii) +    dy*q2
      gzp(llii) = gzp(llii) +    dz*q2
      d2(llii) = d2(llii) +    q3 + q2*(seven-eer2)
      go to 420
c
c    yy
c
  316 continue
      bf=   expond*dy*dy
      vg(llii) = vg(llii) +    bf
      q2=  -bf*ee
      q3=   expond*two
      gxp(llii) = gxp(llii) +    dx*q2
      gyp(llii) = gyp(llii) +    dy*(q2+q3)
      gzp(llii) = gzp(llii) +    dz*q2
      d2(llii) = d2(llii) +    q3 + q2*(seven-eer2)
      go to 420
c
c    zz
c
  317 continue
      bf=   expond*dz*dz
      vg(llii) = vg(llii) +    bf
      q2=  -bf*ee
      q3=   expond*two
      gxp(llii) = gxp(llii) +    dx*q2
      gyp(llii) = gyp(llii) +    dy*q2
      gzp(llii) = gzp(llii) +    dz*(q2+q3)
      d2(llii) = d2(llii) +    q3 + q2*(seven-eer2)
      go to 420
c
c    xy
c
  318 expon3=expond*sq3
      q1=   expon3*dx
      bf=   q1*dy
      vg(llii) = vg(llii) +    bf
      q3=  -bf*ee
      gxp(llii) = gxp(llii) +    q3*dx + expon3*dy
      gyp(llii) = gyp(llii) +    q3*dy + q1
      gzp(llii) = gzp(llii) +    q3*dz
      d2(llii) = d2(llii) +    q3*(seven-eer2)
      go to 420
c
c    xz
c
  319 expon3=expond*sq3
      q1=   expon3*dz
      bf=   q1*dx
      vg(llii) = vg(llii) +    bf
      q3=  -bf*ee
      gxp(llii) = gxp(llii) +    q3*dx + q1
      gyp(llii) = gyp(llii) +    q3*dy
      gzp(llii) = gzp(llii) +    q3*dz + expon3*dx
      d2(llii) = d2(llii) +    q3*(seven-eer2)
      go to 420
c
c    yz
c
  320 expon3=expond*sq3
      q1=   expon3*dy
      bf=   q1*dz
      vg(llii) = vg(llii) +    bf
      q3=  -bf*ee
      gxp(llii) = gxp(llii) +    q3*dx
      gyp(llii) = gyp(llii) +    q3*dy + expon3*dz
      gzp(llii) = gzp(llii) +    q3*dz + q1
      d2(llii) = d2(llii) +    q3*(seven-eer2)
c
  420 continue
c
  660 continue
  720 continue
c
      return
      end
       subroutine  raddat (jan)
       implicit REAL  (a-h, o-z)
INCLUDE(common/radxxx)
INCLUDE(common/radyyy)
       ian =  jan
       ian = 60
       if(ian.eq.0) ian=1
       if(ian.eq.1) then
                ninf=21
                nsup=45
                nrad =25
       endif
       if(ian.ge.2.and.ian.le.10)  then
                ninf=46
                nsup=75
                nrad =30
       endif
       if(ian.gt.10.and.ian.le.18) then
                ninf=76
                nsup=110
                nrad =35
       endif
       if(ian.gt.18.and.ian.le.36) then
                ninf=111
                nsup=150
                nrad =40
       endif
       if(ian.gt.36.and.ian.le.54) then
                ninf=151
                nsup=195
                nrad =45
       endif
       if(ian.gt.54 ) then
                ninf=196
                nsup=245
                nrad =50
       end if
       j=0
       do 100 i=ninf,nsup
       j = j+1
       rcg(j)= rrr(i)
       wcg(j)= www(i)
100    continue
       return
       end
       function smuf(x)
       implicit REAL  (a-h,o-z)
       data ntimes /3/
       arg=x
       do 10 i=1,ntimes
       arg=0.5d0*(arg+arg+arg-arg*arg*arg)
10     continue
       smuf=0.5d0*(1.d0-arg)
       return
       end
      subroutine symeqv(iw)
      implicit REAL  (a-h,o-z)
      logical found
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/dnfnw)
      dimension tt(500)
      equivalence (tt(1),vg(1))
      data zero /0.d0/
      found=.false.
      do  10 iat=1,nat
        ttt=zero
        czani=czan(iat)
        do 1 jat=1,nat
         if(jat.eq.iat) goto 1
         if(iat.gt.jat)
     +   ijat=jat+iat*(iat-1)/2
         if(jat.gt.iat)
     +   ijat=iat+jat*(jat-1)/2
        rijat=rij(ijat)
         ttt=ttt+czani*czan(jat)/rijat
1        continue
        tt(iat)=ttt
10       continue
         natm1=nat-1
         do 20 iat=1,natm1
        if(ndeg(iat).ne.0) goto 20
        czani=czan(iat)
         iatp1=iat+1
               do 2 jat=iatp1,nat
              test=dabs(czani-czan(jat))
              if(test.gt.1.d-8) goto 2
              test=dabs(tt(iat)-tt(jat))
              if(test.gt.1.d-8) goto 2
              ndeg(jat)=iat
              found=.true.
2              continue
20             continue
         if(.not.found) return
        write(iw,9010)
        do  600 iat=1,nat
            if(ndeg(iat).eq.0)  then
            write(iw,9020) iat
            else
            write(iw,9030) iat, ndeg(iat)
            end if
600     continue
9010     format(/,5x,'Symmetry  equivalences found ...',/)
9020     format(5x,'atom  ',i4,'  parent')
9030     format(5x,'atom  ',i4,'  equivalent to atom ',i4)
         return
        end
      subroutine ver_dft(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/dft.m,v $
     +     "/
      data revision /"$Revision: 5780 $"/
      data date /"$Date: 2008-12-14 00:36:30 +0100 (Sun, 14 Dec 2008) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
_ELSE
c DFT option (from berlin) dft.o

      subroutine scdft
      entry scdfoc
      entry scdfgr
      entry becke
      call missing_module('old dft')
      end
      subroutine ver_dft(s,r,d)
      character s*(*),r*(*),d*(*)
      s=" "
      end
_ENDIF
