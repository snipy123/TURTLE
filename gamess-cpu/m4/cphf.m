c 
c  $Author: jmht $
c  $Date: 2015-03-13 21:56:17 +0100 (Fri, 13 Mar 2015) $
c  $Locker:  $
c  $Revision: 6317 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/cphf.m,v $
c  $State: Exp $
c
c the following are omited for the parallel 2nd deriv version
c   chfndr:
c   chfdrv:
c   pfockc:
c   pdens:
c   chfcla:
c   symrhs:
c   ovlcl:
c  
_EXTRACT(chfeq,pclinux)
      subroutine chfeq(q,eps,b,utotal,uold,au,u,maxc,lstop,skipp)
      implicit REAL  (a-h,o-z)
      character *8 fkd
      dimension q(*)
      dimension eps(*),b(*),utotal(*),uold(*),au(mn,*),u(mn,*)
c
c     simultaneous equations for chf - large case
c
      logical lstop,skipp
      dimension skipp(100)
INCLUDE(common/prnprn)
INCLUDE(common/cigrad)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/labij(340),labkl(340)
      common/blkin/g(510),nword
INCLUDE(common/timez)
      common/small/alpha(50,50),aa(50,50),bee(50),cc(50),wks1(50),
     + wks2(50)
c
INCLUDE(common/common)
INCLUDE(common/cndx41)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
      character*10 charwall
c
      data fkd/'fockder'/
c
c     iterative solution of simultaneous equations to give
c     coupled hartree-fock first order wavefunction
c
      if (maxc.gt.50) maxc = 50
      uconv = 10.0d0**(-iconvv)
      lenblk = lensec(mn)
c
c     rhs and solution stored on scratchfile
c     rhs beginning at block iblkb
c     sol. beginning at block iblku
c
      iblkb = iblks + npstar*lenblk
      iblku = iblkb + lenblk*np
      iblk4 = jblk(1)
      idev4 = nofile(1)
      call timit(3)
      tim0 = tim
      tim1 = tim
      iaa = 50
      ifail = 0
      write(iwr,6000) cpulft(1) ,charwall()
c
c     loop over all perturbations taken one at a time
c
      if (oprn(12)) write (iwr,6010)
      if (oprn(13)) write (iwr,6020)
      npst = npstar + 1
      do 150 ko = npst , np
c
c     get rhs for this perturbation
c
         call rdedx(b,mn,iblkb,ifils)
         if (oprn(12)) write (iwr,6030) ko , (b(i),i=1,mn)
         iblkb = iblkb + lenblk
c
c
c     initialise arrays
c
         call vclr(utotal,1,mn)
         if (odebug(2).and.skipp(ko)) write (iwr,6060) ko
         if (.not.(skipp(ko))) then
            call vclr(alpha,1,iaa*iaa)
            call vclr(u,1,mn*maxc)
            call vclr(bee,1,iaa)
            call vclr(au,1,mn*maxc)
c
c     get zeroth order estimate
c
            do 20 i = 1 , mn
               v = -b(i)*eps(i)
               bee(1) = bee(1) + v*v
               uold(i) = v
               u(i,1) = v
 20         continue
c
c     start of iterative solution of chf equations
c     50 iterations are allowed ---  usually less than 10
c     are neccessary
c
            if(oprn(6))write(iwr,6100)ko
            do 110 no = 1 , maxc
c
c     read in the combinations of the 2-electron integrals
c     corresponding to the hessian ( 'a-matrix' )
c
               call search(iblk4,idev4)
c
c     a-matrix on file idev4=nofile(1)=secondary mainfile= ed4 (default)
c     starting block jblk(1) = 1 (default)
c
               call find(idev4)
 30            call get(g(1),nw)
c     have got one block
c
               if (nw.gt.0) then
                  if (nword.gt.0) then
                     call find(idev4)
_IFN1(iv)                     call unpack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)                     call upak4v(g(num2ep+1),labij)
                     if (lcpf .or. cicv .or. cicx) then
                        do 40 i = 1 , nword
_IFN1(iv)                           lab1 = labs(i+i-1)
_IFN1(iv)                           lab2 = labs(i+i)
_IF1(iv)                           lab1 = labij(i)
_IF1(iv)                           lab2 = labkl(i)
                           au(lab1,no) = au(lab1,no) + g(i)*u(lab2,no)
 40                     continue
                     else
                        do 50 i = 1 , nword
_IFN1(iv)                           lab1 = labs(i+i-1)
_IFN1(iv)                           lab2 = labs(i+i)
_IF1(iv)                           lab1 = labij(i)
_IF1(iv)                           lab2 = labkl(i)
                           tt = au(lab1,no) + g(i)*u(lab2,no)
                           au(lab2,no) = au(lab2,no) + g(i)*u(lab1,no)
                           au(lab1,no) = tt
 50                     continue
c
c     go back for another block
c
                     end if
                     go to 30
                  end if
               end if
c
c
               do 60 i = 1 , mn
                  au(i,no) = au(i,no)*eps(i)
 60            continue
               alpha(no,no) = 
     *      ddot(mn,u(1,no),1,u(1,no),1)+ddot(mn,u(1,no),1,au(1,no),1)
               if (no.gt.1) then
                  no1 = no - 1
                  do 70 noo = 1 , no1
                     alpha(noo,no) = ddot(mn,u(1,noo),1,au(1,no),1)
                     alpha(no,noo) = ddot(mn,u(1,no),1,au(1,noo),1)
 70               continue
                  do 80 noo = 1 , no
                     bee(noo) = ddot(mn,u(1,noo),1,u(1,1),1)
 80               continue
                  nnn = no
c
c     nag routine to solve a small set of simultaneous equations
c
                  call f04atf(alpha,iaa,bee,nnn,cc,aa,iaa,wks1,wks2,
     +                        ifail)
               else
                  cc(1) = bee(1)/alpha(1,1)
               end if
               call mxmb(u,1,mn,cc,1,no,utotal,1,mn,mn,no,1)
c
c     check for convergence
c
               call vsub(utotal,1,uold,1,uold,1,mn)
               sumsq = ddot(mn,uold,1,uold,1)/dfloat(mn)
               sumsq = dsqrt(sumsq)
               if (oprn(6)) write (iwr,6040) no , sumsq
               if (sumsq.le.uconv) go to 130
               call vclr(uold,1,mn)
c
c    form new estimate of solution
c
               do 100 mo = 1 , no
                  alp = 
     +        ddot(mn,u(1,mo),1,au(1,no),1) /
     +        ddot(mn,u(1,mo),1,u(1,mo),1)
                  do 90 i = 1 , mn
                     uold(i) = uold(i) + alp*u(i,mo)
 90               continue
 100           continue
c
               call vsub(au(1,no),1,uold,1,u(1,no+1),1,mn)
               if (no.ge.maxc) go to 120
               call dcopy(mn,utotal,1,uold,1)
               call vclr(utotal,1,mn)
 110        continue
 120        write (iwr,6050) ko
         end if
         go to 140
 130     call timit(3)
         write (iwr,6070) no , ko , cpulft(1) ,charwall()
 140     call wrt3(utotal,mn,iblku,ifils)
         iblku = iblku + lenblk
         if (oprn(12) .or. oprn(13)) then
            write (iwr,6080) ko , (utotal(i),i=1,mn)
         end if
         dtim = tim - tim1
         tim1 = tim
         if ((timlim-tim).le.(dtim+dtim)) then
            if (fkder.eq.fkd .and. ko.ne.np) then
               lstop = .true.
               npfin = ko
               ti = tim0
               write (iwr,6090)
               return
            end if
         end if
 150  continue
      ti = tim0
      return
 6000 format(/1x,
     +'commence iterative solutions of chf equations at ',
     + f8.2,' seconds',a10,' wall')
 6010 format (//1x,'print right-hand-side to chf equations')
 6020 format (//1x,'print solutions to chf equations')
 6030 format (//1x,'perturbation  ',i4//(5x,5f16.8))
 6040 format (10x,i5,f15.10)
 6050 format (/10x,'convergence not achieved  ,  component',i4)
 6060 format (1x,'perturbation',i5,' omitted')
 6070 format (/1x,
     + 'chf converged at iteration',i4/1x,
     + 'chf for perturbation',i4,' complete at ',f8.2,' seconds'
     + ,a10,' wall')
 6080 format (//1x,'solution  ',i4//(5x,5f16.8))
 6090 format (//1x,'running out of time!'//)
 6100 format(/6x,'perturbation ',i4/
     +        6x,'iteration',9x,'tester'/
     +        6x,24('=')/)
      end
_ENDEXTRACT
      subroutine chfeqv(q,eps,au,u,work,b,cc,uu,uau,maxc,skipp,
     & npx,irmax,oconv)
      implicit REAL  (a-h,o-z)
c
c     new version of chfeq - vector algorithm -
c
      logical skipp
_IF(rpagrad)
INCLUDE(common/sizes)
INCLUDE(common/rpadcom)
INCLUDE(common/infoa)
      integer mnij, mnab
_ENDIF
INCLUDE(common/cigrad)
      common/blkin/g(510),nword
INCLUDE(common/timez)
      common/small/alpha(50,50),aa(50,50),wks1(50),
     + wks2(50),iblu(50),iblut(50),iblau(50),iatms(100)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
      character*10 charwall
      dimension q(*)
      dimension eps(mn),au(mn,npx),u(mn,npx),b(maxc,npx)
      dimension skipp(100),cc(maxc,npx),uu(maxc,npx)
      dimension work(irmax,mn),uau(maxc,maxc,npx)
c
c     OCONV indicates whether a linear system has converged. 
c     Its dimension is taken to be equal to that of skipp.
c
c     logical oconv(100)
      logical oconv(*)
INCLUDE(common/prnprn)
      data smal/1.0d-13/
      data tich/1.0d-24/
c
c      iterative solution of simultaneous equations to give
c      coupled hartree-fock first order wavefunction
c
      if (maxc.gt.50) maxc = 50
      uconv = 10.0d0**(-iconvv)
      lenblk = lensec(mn)
c
c      rhs and solution stored on scratchfile
c      rhs beginning at block iblkb
c      sol. beginning at block iblku
c
      iblkb = iblks + npstar*lenblk
      iblast = iblks + lenblk*np*2
_IF(rpagrad)
      if (orpagrad) then
         mnij   = nocca*nocca
         mnab   = nvirta*nvirta
         iblkb  = iblkb  + 3*nat*(lensec(mnij)+lensec(mnab))
         iblast = iblast + 3*nat*(lensec(mnij)+lensec(mnab))
      endif
_ENDIF
      iblku = iblkb + lenblk*np
      iblk4 = jblk(1)
      idev4 = nofile(1)
      iaa = 50
      ifail = 0
      write(iwr,6000) cpulft(1) ,charwall()
      if (oprn(12)) write (iwr,6010)
      if (oprn(13)) write (iwr,6020)
c      initialise arrays
c
      nprang = npfin - npstar
      call vclr(uau,1,maxc*maxc*nprang)
      call vclr(u,1,mn*nprang)
      call vclr(b,1,maxc*nprang)
      call vclr(au,1,mn*nprang)
      call vclr(uu,1,maxc*nprang)
      npi = 0
      do 20 ko = npstar + 1 , npfin
c
c      get rhs for this perturbation
c
         oconv(ko) = .false.
         if (skipp(ko)) then
            if(odebug(2)) write (iwr,6030) ko
         else
            npi = npi + 1
            call rdedx(au(1,npi),mn,iblkb,ifils)
            if (oprn(12)) write (iwr,6040) ko , (au(i,npi),i=1,mn)
            iatms(npi) = (ko-1)/3+1
         end if
         iblkb = iblkb + lenblk
 20   continue
c
c      get zeroth order estimate
c
      if (npi.eq.0) go to 290
      do 40 ko = 1 , npi
         do 30 i = 1 , mn
            v = -au(i,ko)*eps(i)
            if (dabs(v).le.tich) v = 0.0d0
            b(1,ko) = b(1,ko) + v*v
            u(i,ko) = v
 30      continue
         if (b(1,ko).le.0.0d0) oconv(ko) = .true.
 40   continue
      iblu(1) = iblast
      ibadd = lensec(mn*npi)
      iblast = iblast + ibadd
      call wrt3(u,mn*npi,iblu(1),ifils)
c
c      start of iterative solution of chf equations
c      50 iterations are allowed ---  usually less than 10
c      are necessary
c
      if(oprn(6)) then
       write(iwr,6100)
      endif
      do 270 no = 1 , maxc
         nox = no
c
c      read in the combinations of the 2-electron integrals
c      corresponding to the hessian ( 'a-matrix' )
c
         call rdedx(u,mn*npi,iblu(no),ifils)
         call vclr(au,1,mn*npi)
         call search(iblk4,idev4)
c
c      a-matrix on file idev4=nofile(1)=secondary mainfile= ed4 (default
c      starting block jblk(1) = 1 (default)
c
         ifi = 1
         ila = min(irmax,mn)
         n0 = 1
c
c     get the first block and unpack labels
c
         call find(idev4)
         if (lcpf .or. cicv .or. cicx) then
 50         call vclr(work,1,mn*irmax)
            call get2a(work,ifi,ila,mn,idev4)
            call mxmau2(work,u,au,mn,ifi,ila,ila-ifi+1,npi,irmax)
            if (ifi.le.mn) go to 50
         else
 60         call vclr(work,1,mn*irmax)
            call get1a(work,ifi,ila,mn,n0,idev4)
            call mxmau1(work,u,au,mn,ifi,ila,ila-ifi+1,npi,irmax)
            if (ifi.le.mn) go to 60
         end if
_IF(ccpdft)
c
c     add DFT contributions
c
         call au_dft(q,u,au,npi,iatms)
_ENDIF
c
c     scale au by difference of eigenvalues
c
         do 80 nn = 1 , npi
            do 70 i = 1 , mn
               au(i,nn) = au(i,nn)*eps(i)
 70         continue
 80      continue
c
c      store au for this iteration
c
         iblau(no) = iblast
         iblast = iblast + ibadd
         call wrt3(au,mn*npi,iblau(no),ifils)
c
c      uu = dot product of u vectors
c
         do 90 nn = 1 , npi
            uu(no,nn) = ddot(mn,u(1,nn),1,u(1,nn),1)
 90      continue
c
c      uau is dot product of u with au
c      last column of uau
c      read au for each iteration
c
         do 110 noo = 1 , no
            call rdedx(au,mn*npi,iblau(noo),ifils)
            do 100 nn = 1 , npi
               uau(no,noo,nn) = ddot(mn,u(1,nn),1,au(1,nn),1)
 100        continue
 110     continue
c
c      last row of uau
c      read u for each iteration
c
         do 130 noo = 1 , no - 1
            call rdedx(u,mn*npi,iblu(noo),ifils)
            do 120 nn = 1 , npi
               uau(noo,no,nn) = ddot(mn,u(1,nn),1,au(1,nn),1)
 120        continue
 130     continue
c
c      nag routine to solve a small set of simultaneous equations
c
         nnn = no
         do 170 nn = 1 , npi
            if (.not.oconv(nn)) then
               do 150 nuu = 1 , no
                  do 140 noo = 1 , no
                     alpha(noo,nuu) = uau(noo,nuu,nn)
 140              continue
 150           continue
               do 160 noo = 1 , no
                  alpha(noo,noo) = alpha(noo,noo) + uu(noo,nn)
 160           continue
               ifail = 0
               call f04atf(alpha,iaa,b(1,nn),nnn,cc(1,nn),aa,iaa,
     +                     wks1,wks2,ifail)
            endif
 170     continue
c
c      form new solution vectors, overwriting au
c
         call vclr(au,1,mn*npi)
         do 200 j = 1 , no
            call rdedx(u,mn*npi,iblu(j),ifils)
            do 190 nn = 1 , npi
               ccjn = cc(j,nn)
               if (dabs(ccjn).gt.tich.and..not.oconv(nn)) then
                  do 180 i = 1 , mn
                     au(i,nn) = au(i,nn) + ccjn*u(i,nn)
 180              continue
               end if
 190        continue
 200     continue
c
c      carry any converged solutions forward
c      note that u is reused for the convergence check
c
         if (no.ne.1) then
            call rdedx(u,mn*npi,iblut(no-1),ifils)
            do nn=1,npi
               if (oconv(nn)) then
                  do i=1,mn
                     au(i,nn) = u(i,nn)
                  enddo
               endif
            enddo
         endif
c
c      write total solution onto file
c
         iblut(no) = iblast
         iblast = iblast + ibadd
         call wrt3(au,mn*npi,iblut(no),ifils)
c
c      check for convergence
c
         if (no.ne.1) then
            gmax = 0.0d0
            do 210 nn = 1 , npi
c
               if (.not.oconv(nn)) then
                  call vsub(au(1,nn),1,u(1,nn),1,u(1,nn),1,mn)
                  gnorm = ddot(mn,u(1,nn),1,u(1,nn),1)/dfloat(mn)
                  gnorm = dsqrt(gnorm)
                  gmax = dmax1(gmax,gnorm)
                  oconv(nn) = gnorm.le.uconv
               endif
 210        continue
            if (oprn(6)) write (iwr,6050) no , gmax
            if (gmax.le.uconv) then
               write (iwr,6090)
               go to 280
            end if
         end if
c
c     form new expansion vectors
c
         call rdedx(au,mn*npi,iblau(no),ifils)
         do 240 mo = 1 , no
            call rdedx(u,mn*npi,iblu(mo),ifils)
            do 230 nn = 1 , npi
               if (.not.oconv(nn)) then
                  fac = uau(mo,no,nn)/uu(mo,nn)
                  do 220 i = 1 , mn
                     au(i,nn) = au(i,nn) - fac*u(i,nn)
 220              continue
               endif
 230        continue
 240     continue
         gmax = 0.0d0
         do 260 nn = 1 , npi
            if (.not.oconv(nn)) then
               do 250 i = 1 , mn
                  if (dabs(au(i,nn)).le.tich) au(i,nn) = 0.0d0
 250           continue
               gnorm = ddot(mn,au(1,nn),1,au(1,nn),1)/dfloat(mn)
               gnorm = dsqrt(gnorm)
               gmax = dmax1(gmax,gnorm)
            endif
 260     continue
         if (oprn(6)) write (iwr,6060) gmax
         if (gmax.le.smal) then
           write (iwr,*) ' converged - new expansion vector negligible '
           go to 280
         end if
c
c
         iblu(no+1) = iblast
         iblast = iblast + ibadd
         call wrt3(au,mn*npi,iblu(no+1),ifils)
c
c
 270  continue
      write (iwr,*) ' no full convergence after 50 iterations '
      write (iwr,*) ' this will require changes to the program ! '
c
 280  call timit(3)
      write (iwr,6070) nox , cpulft(1) ,charwall()
      call rdedx(u,mn*npi,iblut(nox),ifils)
 290  npi = 0
      do 300 ko = npstar + 1 , npfin
         if (skipp(ko)) then
            call vclr(au,1,mn)
            call wrt3(au,mn,iblku,ifils)
         else
            npi = npi + 1
            call wrt3(u(1,npi),mn,iblku,ifils)
            if (oprn(13)) write (iwr,6080) npi , (u(i,npi),i=1,mn)
         end if
         iblku = iblku + lenblk
 300  continue
      return
 6000 format(/1x,
     +'commence iterative solution of chf equations at ',f8.2,
     +' seconds',a10,' wall')
 6010 format (//1x,'print right-hand-side to chf equations')
 6020 format (//1x,'print solutions to chf equations')
 6030 format (1x,'perturbation',i5,' omitted')
 6040 format (//1x,'perturbation  ',i4//(5x,5f16.8))
 6050 format (i10,5x,f15.10)
 6060 format (30x,f20.15)
 6070 format (/1x,
     + 'chf converged at iteration',i4/1x,
     + 'chf complete at ',f8.2,' seconds',a10,' wall')
 6080 format (//1x,'solution  ',i4//(5x,5f16.8))
 6090 format(/1x,'chf converged - wavefunctions stationary')
 6100 format(/
     +  6x,'iteration',9x,'tester',2x,'expansion vector norm'/
     +  6x,47('=')/)
      end
      function memreq_chfeqv(q,skipp,npx)
      implicit REAL  (a-h,o-z)
c
c     new version of chfeq - vector algorithm -
c
      logical skipp
_IF(rpagrad)
INCLUDE(common/sizes)
INCLUDE(common/rpadcom)
INCLUDE(common/infoa)
      integer mnij, mnab
_ENDIF
INCLUDE(common/cigrad)
      common/blkin/g(510),nword
INCLUDE(common/timez)
      common/small/alpha(50,50),aa(50,50),wks1(50),
     + wks2(50),iblu(50),iblut(50),iblau(50),iatms(100)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
      dimension q(*)
c     dimension eps(mn),au(mn,npx),u(mn,npx),b(maxc,npx)
      dimension skipp(100)
c     dimension cc(maxc,npx),uu(maxc,npx)
c     dimension work(irmax,mn),uau(maxc,maxc,npx)
c
c     OCONV indicates whether a linear system has converged. 
c     Its dimension is taken to be equal to that of skipp.
c
c     logical oconv(100)
c     logical oconv(*)
INCLUDE(common/prnprn)
      data smal/1.0d-13/
      data tich/1.0d-24/

      memreq_chfeqv = 0
      npi = 0
      do 20 ko = npstar + 1 , npfin
c
c      get rhs for this perturbation
c
         if (skipp(ko)) then
         else
            npi = npi + 1
            iatms(npi) = (ko-1)/3+1
         end if
 20   continue
_IF(ccpdft)
c
c     add DFT contributions
c
         memreq_chfeqv = memreq_au_dft(q,q,q,npi,iatms)
_ENDIF
      return
 6000 format(/1x,
     +'commence iterative solution of chf equations at ',f8.2,
     +' seconds',a10,' wall')
 6010 format (//1x,'print right-hand-side to chf equations')
 6020 format (//1x,'print solutions to chf equations')
 6030 format (1x,'perturbation',i5,' omitted')
 6040 format (//1x,'perturbation  ',i4//(5x,5f16.8))
 6050 format (i10,5x,f15.10)
 6060 format (30x,f20.15)
 6070 format (/1x,
     + 'chf converged at iteration',i4/1x,
     + 'chf complete at ',f8.2,' seconds',a10,' wall')
 6080 format (//1x,'solution  ',i4//(5x,5f16.8))
 6090 format(/1x,'chf converged - wavefunctions stationary')
 6100 format(/
     +  6x,'iteration',9x,'tester',2x,'expansion vector norm'/
     +  6x,47('=')/)
      end
_IF(ccpdft)
      subroutine au_dft(q,u,au,npi,iatms)
      implicit none
c
c     Add the DFT contributions to the matrix vector products
c
c     Parameters:
c
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      integer m8
      parameter (m8=8)
c
c     Input:
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/atmblk)
INCLUDE(common/infoa)
INCLUDE(common/drive_dft)
      integer npi,iatms(npi)
      REAL u(mn,npi)
      REAL au(mn,npi)
c
c     Workspace:
c
      REAL q(*)
c
c     Functions:
c
INCLUDE(common/ccpdft.hf77)
      integer igmem_alloc_inf
      integer igmem_null
c
c     Local:
c
      integer iavc,ierror,iblok,inull
c
c     Code:
c
      if (.not.CD_active()) return
c
c     get the MO coefficients
c
      iavc = igmem_alloc_inf(num*num,'cphf.m','au_dft','alpha-vectors',
     &                       IGMEM_NORMAL)
      call secget(isect(8),m8,iblok)
      iblok = iblok + mvadd
      call rdedx(q(iavc),num*ncoorb,iblok,ifild)
c
      inull = igmem_null()
      ierror = CD_chf_lhs_mo(q,q,npi,iatms,ogeompert,ncoorb,nocca,0,
     &                       q(iavc),q(inull),u,q(inull),au,q(inull),
     &                       .false.,iwr)
c
      call gmem_free_inf(iavc,'cphf.m','au_dft','alpha-vectors')
      end
      integer function memreq_au_dft(q,u,au,npi,iatms)
      implicit none
c
c     Add the DFT contributions to the matrix vector products
c
c     Parameters:
c
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      integer m8
      parameter (m8=8)
c
c     Input:
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/atmblk)
INCLUDE(common/infoa)
INCLUDE(common/drive_dft)
      integer npi,iatms(npi)
      REAL u(mn,npi)
      REAL au(mn,npi)
c
c     Workspace:
c
      REAL q(*)
c
c     Functions:
c
INCLUDE(common/ccpdft.hf77)
      integer igmem_alloc_inf, igmem_overhead
      integer igmem_null
c
c     Local:
c
      integer iavc,ierror,iblok,inull
c
c     Code:
c
      memreq_au_dft = 0
      if (.not.CD_active()) return
      inull = igmem_null()
      iavc = inull
      memreq_au_dft = num*num + igmem_overhead() +
     &  CD_memreq_chf_lhs_mo(q,q,npi,iatms,ogeompert,ncoorb,nocca,0,
     &                       q(iavc),q(inull),u,q(inull),au,q(inull),
     &                       .false.,iwr)
      end
_ENDIF
_IFN(secd_parallel)
_IF(rpagrad)
c
c-----------------------------------------------------------------------
c
      subroutine symrhs_ij(qq,ibstar,skipp,mapnr,iso,nshels)
c
c     symmetrise r.h.s. ( d2h and subgroups only )
c     occupied-occupied blocks only (Huub van Dam, 1999)
c
      implicit REAL  (a-h,o-z)
      logical skipp
INCLUDE(common/sizes)
      dimension skipp(3,nat),mapnr(*)
      dimension qq(*),iso(nshels,*)
c
INCLUDE(common/cigrad)
      common/mpshl/ns(maxorb)
INCLUDE(common/nshel)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
cjiri
c IN CLUDE(common/cphf)
c
      common/bufb/ptr(3,144),ict(maxat,8)
      common/symmos/imos(8,maxorb)
      character *8 grhf
      data one/1.0d0/
      data grhf/'grhf'/
c
      call rdedx(ptr(1,1),nw196(1),ibl196(1),ifild)
      call rdedx(iso,nw196(5),ibl196(5),ifild)
      do 40 ii = 1 , nshell
         ic = katom(ii)
         do 30 it = 1 , nt
            id = iso(ii,it)
            ict(ic,it) = katom(id)
 30      continue
 40   continue
c
      do 80 n = 1 , nat
         do 50 i = 1 , 3
            skipp(i,n) = .false.
 50      continue
         do 70 nop = 1 , nt
            if (ict(n,nop).gt.n) then
               do 60 i = 1 , 3
                  skipp(i,n) = .true.
 60            continue
               go to 80
            end if
 70      continue
 80   continue
      do 110 n = 1 , nat
         do 90 nop = 1 , nt
            if (ict(n,nop).ne.n) go to 110
 90      continue
         do 100 i = 1 , 3
            skipp(i,n) = .true.
 100     continue
c        nuniq = n
         go to 120
 110  continue
 120  continue
cjiri-cphf
c - ignore transl invariance for first
c     if(itransinvar.eq.0) then
c     skipp(1,1)=.false.
c     skipp(2,1)=.false.
c     skipp(3,1)=.false.
c     endif
cjiriend
      mnij = nocca*nocca
      mnnrij = mnij
      ntpls1 = noccb + 1
      nplus1 = nocca + 1
      nsoc = noccb - nocca
      nvirta = nsa4 - noccb
      ibll = lensec(mnij)
      iblku = ibstar
      an = one/dfloat(nt)
      ioff = mnij + 1
      nat3 = nat*3
c     read in u vectors
      do 130 n = 1 , nat3
         call rdedx(qq(ioff),mnij,iblku,ifils)
         iblku = iblku + ibll
         ioff = ioff + mnij
 130  continue
c     loop over vectors
      iblku = ibstar
      do 370 n = 1 , nat
         do 360 nc = 1 , 3
            ioff = ((n-1)*3+nc)*mnij
c     copy vector for atom n, component nc into work area
            do 140 i = 1 , mnij
               qq(i) = qq(ioff+i)
 140        continue
c     work along the elements of this vector
c loop over double-single and double-virtual
            if (scftyp.eq.grhf) then
               ij = 0
               do 180 i = 1 , nsa4
                  do 170 ia = 1 , i
                     if (ns(i).ne.ns(ia)) then
                        ij = ij + 1
c     loop over symmetry operations
c     except identity
                        do 160 iop = 2 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           ioff = (niop-1)*3*mnij
                           npnc = (iop-1)*3 + nc
                           do 150 k = 1 , 3
                              ioff = ioff + mnij
                              qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                                 + qq(ij)
 150                       continue
 160                    continue
                     end if
 170              continue
 180           continue
               if (.not.(.not.lcpf .and. .not.cicv .and. (.not.cicx)))
     +             then
                  do 220 i = 1 , nsa4
                     do 210 ia = 1 , i
                        iia = i*(i-1)/2 + ia
                        if (mapnr(iia).lt.0) then
                           ij = mnnrij - mapnr(iia)
                           do 200 iop = 2 , nt
                              isign = imos(iop,i)*imos(iop,ia)
                              sign = dfloat(isign)
                              niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                              ioff = (niop-1)*3*mnij
                              npnc = (iop-1)*3 + nc
                              do 190 k = 1 , 3
                                 ioff = ioff + mnij
                                 qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                              + qq(ij)
 190                          continue
 200                       continue
                        end if
 210                 continue
 220              continue
               end if
            else
               if (nocca.ne.0) then
                  do 260 i = 1 , nocca
                     do 250 ia = 1 , nocca
                        ij = (ia-1)*nocca + i
c     loop over symmetry operations
c     except identity
                        do 240 iop = 2 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           ioff = (niop-1)*3*mnij
                           npnc = (iop-1)*3 + nc
                           do 230 k = 1 , 3
                              ioff = ioff + mnij
                              qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                                 + qq(ij)
 230                       continue
 240                    continue
 250                 continue
 260              continue
                  if (.not.(.not.lcpf .and. .not.cicv .and. (.not.cicx))
     +                ) then
                     do 300 i = 1 , nocca
                        do 290 ia = 1 , i
                           iia = i*(i-1)/2 + ia
                           if (mapnr(iia).lt.0) then
                              ij = mnnrij - mapnr(iia)
                              do 280 iop = 2 , nt
                                 isign = imos(iop,i)*imos(iop,ia)
                                 sign = dfloat(isign)
                                 niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                                 ioff = (niop-1)*3*mnij
                                 npnc = (iop-1)*3 + nc
                                 do 270 k = 1 , 3
                                    ioff = ioff + mnij
                                    qq(ij) = ptr(k,npnc)
     +                                 *sign*qq(ioff+ij) + qq(ij)
 270                             continue
 280                          continue
                           end if
 290                    continue
 300                 continue
                  end if
               end if
            end if
            do 350 i = 1 , mnij
               qq(i) = an*qq(i)
 350        continue
            call wrt3(qq(1),mnij,iblku,ifils)
            iblku = iblku + ibll
 360     continue
 370  continue
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine symrhs_ab(qq,ibstar,skipp,mapnr,iso,nshels)
c
c     symmetrise r.h.s. ( d2h and subgroups only )
c     virtual-virtual blocks only (Huub van Dam,1999)
c
      implicit REAL  (a-h,o-z)
      logical skipp
INCLUDE(common/sizes)
      dimension skipp(3,nat),mapnr(*)
      dimension qq(*),iso(nshels,*)
c
INCLUDE(common/cigrad)
      common/mpshl/ns(maxorb)
INCLUDE(common/nshel)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
cjiri
c IN_CLUDE(common/cphf)
c
      common/bufb/ptr(3,144),ict(maxat,8)
      common/symmos/imos(8,maxorb)
      character *8 grhf
      data one/1.0d0/
      data grhf/'grhf'/
c
      call rdedx(ptr(1,1),nw196(1),ibl196(1),ifild)
      call rdedx(iso,nw196(5),ibl196(5),ifild)
      do 40 ii = 1 , nshell
         ic = katom(ii)
         do 30 it = 1 , nt
            id = iso(ii,it)
            ict(ic,it) = katom(id)
 30      continue
 40   continue
c
      do 80 n = 1 , nat
         do 50 i = 1 , 3
            skipp(i,n) = .false.
 50      continue
         do 70 nop = 1 , nt
            if (ict(n,nop).gt.n) then
               do 60 i = 1 , 3
                  skipp(i,n) = .true.
 60            continue
               go to 80
            end if
 70      continue
 80   continue
      do 110 n = 1 , nat
         do 90 nop = 1 , nt
            if (ict(n,nop).ne.n) go to 110
 90      continue
         do 100 i = 1 , 3
            skipp(i,n) = .true.
 100     continue
c        nuniq = n
         go to 120
 110  continue
 120  continue
cjiri-cphf
c - ignore transl invariance for first
c     if(itransinvar.eq.0) then
c     skipp(1,1)=.false.
c     skipp(2,1)=.false.
c     skipp(3,1)=.false.
c     endif
cjiriend
      ntpls1 = noccb + 1
      nplus1 = nocca + 1
      nsoc = noccb - nocca
      nvirta = nsa4 - noccb
      mnij = nocca*nocca
      mnab = nvirta*nvirta
      mnnrab = mnab
      ibll = lensec(mnab)
      iblku = ibstar+3*nat*lensec(mnij)
      an = one/dfloat(nt)
      ioff = mnab + 1
      nat3 = nat*3
c     read in u vectors
      do 130 n = 1 , nat3
         call rdedx(qq(ioff),mnab,iblku,ifils)
         iblku = iblku + ibll
         ioff = ioff + mnab
 130  continue
c     loop over vectors
      iblku = ibstar+3*nat*lensec(mnij)
      do 370 n = 1 , nat
         do 360 nc = 1 , 3
            ioff = ((n-1)*3+nc)*mnab
c     copy vector for atom n, component nc into work area
            do 140 i = 1 , mnab
               qq(i) = qq(ioff+i)
 140        continue
c     work along the elements of this vector
c loop over double-single and double-virtual
            if (scftyp.eq.grhf) then
               ij = 0
               do 180 i = 1 , nsa4
                  do 170 ia = 1 , i
                     if (ns(i).ne.ns(ia)) then
                        ij = ij + 1
c     loop over symmetry operations
c     except identity
                        do 160 iop = 2 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           ioff = (niop-1)*3*mnab
                           npnc = (iop-1)*3 + nc
                           do 150 k = 1 , 3
                              ioff = ioff + mnab
                              qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                                 + qq(ij)
 150                       continue
 160                    continue
                     end if
 170              continue
 180           continue
               if (.not.(.not.lcpf .and. .not.cicv .and. (.not.cicx)))
     +             then
                  do 220 i = 1 , nsa4
                     do 210 ia = 1 , i
                        iia = i*(i-1)/2 + ia
                        if (mapnr(iia).lt.0) then
                           ij = mnnrab - mapnr(iia)
                           do 200 iop = 2 , nt
                              isign = imos(iop,i)*imos(iop,ia)
                              sign = dfloat(isign)
                              niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                              ioff = (niop-1)*3*mnab
                              npnc = (iop-1)*3 + nc
                              do 190 k = 1 , 3
                                 ioff = ioff + mnab
                                 qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                              + qq(ij)
 190                          continue
 200                       continue
                        end if
 210                 continue
 220              continue
               end if
            else
               if (nocca.ne.0) then
                  do 260 i = nplus1 , nsa4
                     do 250 ia = nplus1 , nsa4
chvd                    ij = (ia-nocca-1)*nocca + i-nocca
                        ij = (ia-nocca-1)*(nsa4-nocca) + i-nocca
c     loop over symmetry operations
c     except identity
                        do 240 iop = 2 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           ioff = (niop-1)*3*mnab
                           npnc = (iop-1)*3 + nc
                           do 230 k = 1 , 3
                              ioff = ioff + mnab
                              qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                                 + qq(ij)
 230                       continue
 240                    continue
 250                 continue
 260              continue
                  if (.not.(.not.lcpf .and. .not.cicv .and. (.not.cicx))
     +                ) then
                     do 300 i = 1 , nsa4
                        do 290 ia = 1 , i
                           iia = i*(i-1)/2 + ia
                           if (mapnr(iia).lt.0) then
                              ij = mnnrab - mapnr(iia)
                              do 280 iop = 2 , nt
                                 isign = imos(iop,i)*imos(iop,ia)
                                 sign = dfloat(isign)
                                 niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                                 ioff = (niop-1)*3*mnab
                                 npnc = (iop-1)*3 + nc
                                 do 270 k = 1 , 3
                                    ioff = ioff + mnab
                                    qq(ij) = ptr(k,npnc)
     +                                 *sign*qq(ioff+ij) + qq(ij)
 270                             continue
 280                          continue
                           end if
 290                    continue
 300                 continue
                  end if
               end if
            end if
            do 350 i = 1 , mnab
               qq(i) = an*qq(i)
 350        continue
            call wrt3(qq(1),mnab,iblku,ifils)
            iblku = iblku + ibll
 360     continue
 370  continue
      return
      end
c
c-----------------------------------------------------------------------
c
_ENDIF
      subroutine symrhs(qq,ibstar,skipp,mapnr,iso,nshels)
c
c    symmetrise r.h.s. ( d2h and subgroups only )
c
      implicit REAL  (a-h,o-z)
      logical skipp
INCLUDE(common/sizes)
      dimension skipp(3,nat),mapnr(*)
      dimension qq(*),iso(nshels,*)
c
INCLUDE(common/cigrad)
      common/mpshl/ns(maxorb)
INCLUDE(common/nshel)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
c IN_CLUDE(common/cphf)
_IF(rpagrad)
INCLUDE(common/rpadcom)
_ENDIF
c
      common/bufb/ptr(3,144),ict(maxat,8)
      common/symmos/imos(8,maxorb)
      character *8 grhf
      data one/1.0d0/
      data grhf/'grhf'/
c
c
c
      call rdedx(ptr(1,1),nw196(1),ibl196(1),ifild)
      nav = lenwrd()
      call readi(iso,nw196(5)*nav,ibl196(5),ifild)
      do 40 ii = 1 , nshell
         ic = katom(ii)
         do 30 it = 1 , nt
            id = iso(ii,it)
            ict(ic,it) = katom(id)
 30      continue
 40   continue
c
      do 80 n = 1 , nat
         do 50 i = 1 , 3
            skipp(i,n) = .false.
 50      continue
         do 70 nop = 1 , nt
            if (ict(n,nop).gt.n) then
               do 60 i = 1 , 3
                  skipp(i,n) = .true.
 60            continue
               go to 80
            end if
 70      continue
 80   continue
      do 110 n = 1 , nat
         do 90 nop = 1 , nt
            if (ict(n,nop).ne.n) go to 110
 90      continue
         do 100 i = 1 , 3
            skipp(i,n) = .true.
 100     continue
c        nuniq = n
         go to 120
 110  continue
 120  continue
cjiri-cphf
c - ignore transl invariance for first
c     if(itransinvar.eq.0) then
c     skipp(1,1)=.false.
c     skipp(2,1)=.false.
c     skipp(3,1)=.false.
c     endif
cjiriend
      ntpls1 = noccb + 1
      nplus1 = nocca + 1
      nsoc = noccb - nocca
      nvirta = nsa4 - noccb
      ibll = lensec(mn)
_IF(rpagrad)
      if (orpagrad) then
         mnij = nocca*nocca
         mnab = nvirta*nvirta
         iblku = ibstar+3*nat*(lensec(mnij)+lensec(mnab))
      else
         iblku = ibstar
      endif
_ELSE
      iblku = ibstar
_ENDIF
      an = one/dfloat(nt)
      ioff = mn + 1
      nat3 = nat*3
c     read in u vectors
      do 130 n = 1 , nat3
         call rdedx(qq(ioff),mn,iblku,ifils)
         iblku = iblku + ibll
         ioff = ioff + mn
 130  continue
c     loop over vectors
_IF(rpagrad)
      if (orpagrad) then
         mnij = nocca*nocca
         mnab = nvirta*nvirta
         iblku = ibstar+3*nat*(lensec(mnij)+lensec(mnab))
      else
         iblku = ibstar
      endif
_ELSE
      iblku = ibstar
_ENDIF
      do 370 n = 1 , nat
         do 360 nc = 1 , 3
            ioff = ((n-1)*3+nc)*mn
c     copy vector for atom n, component nc into work area
            do 140 i = 1 , mn
               qq(i) = qq(ioff+i)
 140        continue
c     work along the elements of this vector
c loop over double-single and double-virtual
            if (scftyp.eq.grhf) then
               ij = 0
               do 180 i = 1 , nsa4
                  do 170 ia = 1 , i
                     if (ns(i).ne.ns(ia)) then
                        ij = ij + 1
c     loop over symmetry operations
c     except identity
                        do 160 iop = 2 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           ioff = (niop-1)*3*mn
                           npnc = (iop-1)*3 + nc
                           do 150 k = 1 , 3
                              ioff = ioff + mn
                              qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                                 + qq(ij)
 150                       continue
 160                    continue
                     end if
 170              continue
 180           continue
               if (.not.(.not.lcpf .and. .not.cicv .and. (.not.cicx)))
     +             then
                  do 220 i = 1 , nsa4
                     do 210 ia = 1 , i
                        iia = i*(i-1)/2 + ia
                        if (mapnr(iia).lt.0) then
                           ij = mnnr - mapnr(iia)
                           do 200 iop = 2 , nt
                              isign = imos(iop,i)*imos(iop,ia)
                              sign = dfloat(isign)
                              niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                              ioff = (niop-1)*3*mn
                              npnc = (iop-1)*3 + nc
                              do 190 k = 1 , 3
                                 ioff = ioff + mn
                                 qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                              + qq(ij)
 190                          continue
 200                       continue
                        end if
 210                 continue
 220              continue
               end if
            else
               if (nocca.ne.0) then
                  do 260 i = 1 , nocca
                     do 250 ia = nplus1 , nsa4
                        ij = (ia-nocca-1)*nocca + i
c     loop over symmetry operations
c     except identity
                        do 240 iop = 2 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           ioff = (niop-1)*3*mn
                           npnc = (iop-1)*3 + nc
                           do 230 k = 1 , 3
                              ioff = ioff + mn
                              qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                                 + qq(ij)
 230                       continue
 240                    continue
 250                 continue
 260              continue
                  if (.not.(.not.lcpf .and. .not.cicv .and. (.not.cicx))
     +                ) then
                     do 300 i = 1 , nsa4
                        do 290 ia = 1 , i
                           iia = i*(i-1)/2 + ia
                           if (mapnr(iia).lt.0) then
                              ij = mnnr - mapnr(iia)
                              do 280 iop = 2 , nt
                                 isign = imos(iop,i)*imos(iop,ia)
                                 sign = dfloat(isign)
                                 niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                                 ioff = (niop-1)*3*mn
                                 npnc = (iop-1)*3 + nc
                                 do 270 k = 1 , 3
                                    ioff = ioff + mn
                                    qq(ij) = ptr(k,npnc)
     +                                 *sign*qq(ioff+ij) + qq(ij)
 270                             continue
 280                          continue
                           end if
 290                    continue
 300                 continue
                  end if
               end if
               if (noccb.ne.nocca) then
c open shell only - loop over single-virtual
                  do 340 i = nplus1 , noccb
                     do 330 ia = ntpls1 , nsa4
                        ij = nvirta*nocca + (ia-nsoc-1)*nsoc + i - nocca
c     loop over symmetry operations
c     except identity
                        do 320 iop = 2 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           ioff = (niop-1)*3*mn
                           npnc = (iop-1)*3 + nc
                           do 310 k = 1 , 3
                              ioff = ioff + mn
                              qq(ij) = ptr(k,npnc)*sign*qq(ioff+ij)
     +                                 + qq(ij)
 310                       continue
 320                    continue
 330                 continue
 340              continue
               end if
            end if
            do 350 i = 1 , mn
               qq(i) = an*qq(i)
 350        continue
            call wrt3(qq(1),mn,iblku,ifils)
            iblku = iblku + ibll
 360     continue
 370  continue
      return
      end
      subroutine chfcla(qq,iqq)
c
c    assemble coupled hartree fock contribution to closed shell
c    scf second derivatives
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical out
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
      common/maxlen/maxq
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/mapper)
      common/bufb/ioffn(maxat*3),icol(maxorb)
INCLUDE(common/symtry)
      dimension qq(*),iqq(*)
INCLUDE(common/prnprn)
c
c     contibution from first derivative of density matrix
c     with first derivative of integrals
c
      nat3 = nat*3
      nlen = nat3*nat3
      iof = lenrel(nw196(5))
      iofs = nw196(5) + lenint(nat*nt)
      i10 = iofs + 1
      i11 = i10 + nlen
      maxw = maxq - nlen - nx - iofs
      if (maxw.lt.(nx*3)) call caserr(' insufficient core')
      do 20 i = 1 , nat3
         icol(i) = (i-1)*nat3 + iofs
 20   continue
      call vclr(qq(i10),1,nlen)
      ltri = ikyp(ncoorb)
      lenblk = lensec(ltri)
      out = odebug(6)
c     density matrix derivatives section 15
      iposd = iochf(15)
      npass = 1
      maxnuc = 0
      nadd = nat
      ntot = nx*nat3
 30   if (ntot.le.maxw) then
         do 50 ipass = 1 , npass
            minnuc = maxnuc + 1
            maxnuc = maxnuc + nadd
            if (maxnuc.gt.nat) maxnuc = nat
            nuc = maxnuc - minnuc + 1
            nuc3 = nuc*3
            k = (minnuc-1)*3 + 1
            ioffn(k) = nlen + nx + i10
            do 40 i = 1 , nuc3
               ioffn(k+1) = ioffn(k) + nx
               k = k + 1
 40         continue
 50      continue
         maxnuc = 0
         do 90 ipass = 1 , npass
c
c     derivatives of fock matrix (m.o. basis, no wavefunction term)
c     at section 13
            iposf = iochf(13)
            minnuc = maxnuc + 1
            maxnuc = maxnuc + nadd
            if (maxnuc.gt.nat) maxnuc = nat
            nuc = maxnuc - minnuc + 1
            nuc3 = nuc*3
            do 60 k = 1 , nuc3
               ioff = ioffn(k)
c
c     read perturbed density matrices
c
               call rdedx(qq(ioff),ltri,iposd,ifockf)
               iposd = iposd + lenblk
 60         continue
            do 80 nn = 1 , nat3
c
c     read derivative fock matrix
c
               call rdedx(qq(i11),ltri,iposf,ifockf)
               iposf = iposf + lenblk
               k = (minnuc-1)*3
               do 70 kk = 1 , nuc3
                  ioff = ioffn(k+kk)
c
c     contribution to second derivative
c
                  dum = tracep(qq(i11),qq(ioff),ncoorb)
                  qq(k+kk+icol(nn)) = dum
 70            continue
 80         continue
 90      continue
         call rdedx(qq(1),nw196(5),ibl196(5),ifild)
         if (out) then
            call dr2sym(qq(i10),qq(i11),iqq(1),iqq(iof+1),nat,nat3,
     +      nshell)
            write (iwr,6010)
            call prnder(qq(i10),nat3,iwr)
         end if
         call secget(isect(60),60,isec46)
         call rdedx(qq(i11),nlen,isec46,ifild)
         call vadd(qq(i11),1,qq(i10),1,qq(i11),1,nlen)
         call dr2sym(qq(i11),qq(i10),iqq(1),iqq(iof+1),nat,nat3,
     +               nshell)
         call wrt3(qq(i11),nlen,isec46,ifild)
         if (out) then
            write (iwr,6020)
            call prnder(qq(i11),nat3,iwr)
         end if
c        return
      else
         npass = npass + 1
         nadd = nat/npass + 1
         ntot = nadd*3*nx
         go to 30
      end if
 6010 format (//' coupled hartree-fock contribution')
 6020 format (//' total so far')
      end
_ENDIF
      subroutine chfopa(qq,iqq)
c
c    assemble coupled hartree fock contribution to open shell
c    ( high-spin) scf second derivatives
c
      implicit REAL  (a-h,o-z)
      logical out
INCLUDE(common/sizes)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
      common/maxlen/maxq
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/mapper)
      common/bufb/ioffn(maxat*3),icol(maxorb)
INCLUDE(common/symtry)
      dimension qq(*),iqq(*)
INCLUDE(common/prnprn)
c
c     contibution from first derivative of density matrix
c     with first derivative of integrals
c
      nat3 = nat*3
      nlen = nat3*nat3
      iof = lenrel(nw196(5))
      iofs = nw196(5) + lenint(nat*nt)
      i10 = iofs + 1
      i11 = i10 + nlen
      i12 = i11 + nx
      maxw = maxq - nlen - nx - nx - iofs
      if (maxw.lt.(nx*6)) call caserr(' insufficient core')
      do 20 i = 1 , nat3
         icol(i) = (i-1)*nat3 + i10 - 1
 20   continue
      call vclr(qq(i10),1,nlen)
      ltri = ikyp(ncoorb)
      lenblk = lensec(ltri)
      out = odebug(6)
c     density matrix derivatives section 15
      iposd = iochf(15)
      npass = 1
      maxnuc = 0
      nadd = nat
      ntott = nx*nat3*2
 30   if (ntott.le.maxw) then
         do 50 ipass = 1 , npass
            minnuc = maxnuc + 1
            maxnuc = maxnuc + nadd
            if (maxnuc.gt.nat) maxnuc = nat
            nuc = maxnuc - minnuc + 1
            nuc3 = nuc*3
            k = (minnuc-1)*3 + 1
            ioffn(k) = nlen + nx + nx + i10
            do 40 i = 1 , nuc3
               ioffn(k+1) = ioffn(k) + nx
               k = k + 1
 40         continue
 50      continue
         maxnuc = 0
         do 110 ipass = 1 , npass
c
c     derivatives of fock matrix (m.o. basis, no wavefunction term)
c     at section 13. followed by derivatives of k matrix,(ka).
            iposf = iochf(13)
            iposk = iposf + 3*nat*lenblk
c  derivatives of overlap matrices at section 14
            iposs = iochf(14)
c  derivatives of density matrices at section 15
            iposd = iochf(15)
            minnuc = maxnuc + 1
            maxnuc = maxnuc + nadd
            if (maxnuc.gt.nat) maxnuc = nat
            nuc = maxnuc - minnuc + 1
            nuc3 = nuc*3
            nword3 = nuc3*nx
            do 60 k = 1 , nuc3
               ioff = ioffn(k)
c     read perturbed density matrix
               call rdedx(qq(ioff),ltri,iposd,ifockf)
c     read derivative overlap matrix
               call rdedx(qq(ioff+nword3),ltri,iposs,ifockf)
               iposd = iposd + lenblk
               iposs = iposs + lenblk
 60         continue
            do 100 nn = 1 , nat3
c     read derivative fock matrix
               call rdedx(qq(i11),ltri,iposf,ifockf)
c     read derivative k matrix
               call rdedx(qq(i12),ltri,iposk,ifockf)
               do 80 i = 1 , ncoorb
                  foci = 0.0d0
                  if (i.le.nb) foci = 1.0d0
                  if (i.le.na) foci = 2.0d0
                  do 70 j = 1 , i
                     focj = 0.0d0
                     if (j.le.nb) focj = 1.0d0
                     if (j.le.na) focj = 2.0d0
                     ijlen = i*(i-1)/2 + j - 1
                     qq(i11+ijlen) = qq(i11+ijlen) - (2.0d0-foci-focj)
     +                               *qq(i12+ijlen)
                     qq(i12+ijlen) = foci*focj*qq(i12+ijlen)
 70               continue
 80            continue
               iposf = iposf + lenblk
               iposk = iposk + lenblk
               k = (minnuc-1)*3
               do 90 kk = 1 , nuc3
                  ioff = ioffn(k+kk)
                  dum1 = tracep(qq(i11),qq(ioff),ncoorb)
                  dum2 = tracep(qq(i12),qq(ioff+nword3),nb)
                  qq(k+kk+icol(nn)) = dum1 + dum2
 90            continue
 100        continue
 110     continue
         call rdedx(qq(1),nw196(5),ibl196(5),ifild)
         if (out) then
            call dr2sym(qq(i10),qq(i11),iqq(1),iqq(iof+1),nat,nat3,
     +                  nshell)
            write (iwr,6010)
            call prnder(qq(i10),nat3,iwr)
         end if
         call secget(isect(60),60,isec46)
         call rdedx(qq(i11),nlen,isec46,ifild)
         call vadd(qq(i11),1,qq(i10),1,qq(i11),1,nlen)
         call dr2sym(qq(i11),qq(i10),iqq(1),iqq(iof+1),nat,nat3,
     +               nshell)
         call wrt3(qq(i11),nlen,isec46,ifild)
         if (out) then
            write (iwr,6020)
            call prnder(qq(i11),nat3,iwr)
         end if
         return
      else
         npass = npass + 1
         nadd = nat/npass + 1
         ntott = nadd*6*nx
         go to 30
      end if
 6010 format (//' coupled hartree-fock contribution')
 6020 format (//' total so far')
      end
_IFN(secd_parallel)
      subroutine chfndr(q,iq)
c
c    driving routine for nuclear displacement chf routines
c    -----------------------------------------------------
c
      implicit REAL  (a-h,o-z)
      logical lstop,skipp,acore
INCLUDE(common/sizes)
      common/lsort/skipp(3*maxat)
      common/maxlen/maxq
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/ghfblk)
      logical lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis
      common/scfblk/en,etot,ehf,sh1(2),sh2(2),gap1(2),gap2(2),
     1              d12,d13,d23,canna,cannb,cannc,fx,fy,fz,
     2              lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis,
     3              ncyc,ischm,lock,maxit,nconv,npunch,lokcyc
      common/mpshl/ns(maxorb)
INCLUDE(common/symtry)
INCLUDE(common/statis)
INCLUDE(common/timeperiods)
INCLUDE(common/drive_dft)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
      logical ogeompert_save
_IF(rpagrad)
INCLUDE(common/rpadcom)
_ENDIF
      dimension iq(*), q(*)
      character *8 grhf,oscf,closed
      data grhf/'grhf'/
      data oscf/'oscf'/
      data closed/'closed'/
c
_IF(ccpdft)
      ierror = CD_set_2e()
_ENDIF
      nav = lenwrd()
      lenx = lensec(nx)*nat*15
      call cpuwal(begin,ebegin)
      call wrt3z(iblks,ifils,lenx)
      write (iwr,6010)
      if (scftyp.eq.oscf) then
         if((dabs(canna-2.0d0).gt.1.0d-6).or.
     +      (dabs(cannb).gt.1.0d-6).or.
     +      (dabs(cannc+2.0d0).gt.1.0d-6)) then
            write (iwr,6020)
            call caserr('stop')
         end if
      end if
      np = nat*3
      if (scftyp.eq.grhf) then
c
         mtype = 0
         call secget(isect(53),mtype,iblok)
         call readi(nact,lds(isect(53))*nav,iblok,ifild)
c
         call derlag(q,erga,ergb,fjk)
         call bfnshl(ns,nsa4)
         imap = igmem_alloc(lenint(nx))
         iimap = lenrel(imap-1)+1
         call ijmapr(nsa4,ns,iq(iimap),mn,mnx)
         ieps = igmem_alloc(mn)
c
         lenblk = lensec(mn)
         ibeta = iblks + lenblk*nat*6
         ibzeta = ibeta + lensec(nx)
c
         i01 = igmem_alloc(nx)
         i1  = igmem_alloc(nx*njk1)
         i2  = igmem_alloc_all(maxa)
         call lgrhfm(q(i01),ibeta,erga,ergb,fjk)
         call lgrhf(q(i1),ibzeta,erga,ergb,fjk)
         call chfgrs(q(ieps),iq(iimap),q(i01),q(i1),q(i2),
     +               ibeta,ibzeta,maxa)
         call gmem_free(i2)
         call gmem_free(i1)
         call gmem_free(i01)
c
         i01 = igmem_alloc(mn*nat)
         i1  = igmem_alloc(mn*nat)
         nxt3 = nx*(5+njk1) + mn*3
         nxt1 = mn*nat+3*max(num*num,nx*nat)+nx*(njk1+1)
         maxa = igmem_max_memory()
         if (nxt1.le.maxa) then
            i2  = igmem_alloc(mn*nat)
            i3  = igmem_alloc(max(num*num,nx*nat))
            i4  = igmem_alloc(max(num*num,nx*nat))
            i5  = igmem_alloc(max(num*num,nx*nat))
            i6  = igmem_alloc(nx)
            i7  = igmem_alloc(nx*njk1)
            i8  = i3
            i9  = i4
            i10 = i5
            acore = .true.
         else
            call caserr("What a mess! Out store rhsgvb not coded???")
            if (nxt3.gt.maxq) then
               write (iwr,6030)
               call caserr('stop')
            end if
            i6 = i2 + mn
            i7 = i6 + nx
            i3 = i7 + nx*njk1
            i4 = i3 + num*num
            i5 = i4 + num*num
            i8 = i5 + num*num
            i9 = i8 + nx
            i10 = i9 + nx
            acore = .false.
         end if
         call rhsgvb(iq(iimap),q(i01),q(i1),q(i2),q(i3),q(i4),
     +        q(i5),q(i6),q(i7),q(i8),q(i9),q(i10),acore,
     +        erga,ergb,ibeta,ibzeta)
         if (acore) then
            call gmem_free(i7)
            call gmem_free(i6)
            call gmem_free(i5)
            call gmem_free(i4)
            call gmem_free(i3)
            call gmem_free(i2)
         else
         endif
         call gmem_free(i1)
         call gmem_free(i01)
c
         i01 = igmem_alloc(mn*(3*nat+1))
         iso = igmem_alloc(nw196(5))
         iiso = lenrel(iso-1)+1
         call symrhs(q(i01),iblks,skipp,iq(iimap),iq(iiso),nshell)
         call gmem_free(iso)
         call gmem_free(i01)
         lenblk = lensec(mn)
         iblku = iblks + np*lenblk
         lstop = .false.
c
c        solve linear equations
c
         ogeompert_save = ogeompert
         ogeompert = .true.
         call chfdrv(q(ieps),lstop,skipp)
         ogeompert = ogeompert_save
         call gmem_free(ieps)
         call gmem_free(imap)
      else
         mn = noccb*nvirta + (noccb-nocca)*nocca
         call grhfbl(scftyp)
         call bfnshl(ns,nsa4)
c
c      sort out a-matrix
c
         i01 = igmem_alloc_all(maxa)
         if (scftyp.eq.closed) call chfcls(q(i01),maxa)
         if (scftyp.eq.oscf) call chfops(q(i01),maxa)
         call gmem_free(i01)
c
_IF(rpagrad)
         mnij = nocca*nocca
         mnab = nvirta*nvirta
         if (orpagrad) then
            mnmx = max(mn,mnij,mnab)
         else
            mnmx = mn
         endif
_ELSE
         mnmx = mn
_ENDIF
         ieps = igmem_alloc(mnmx)
         ibx  = igmem_alloc(mnmx)
         iby  = igmem_alloc(mnmx)
         ibz  = igmem_alloc(mnmx)
         ieval= igmem_alloc(num)
c
c     r.h.s of equations
c
         if (scftyp.eq.closed) then
            call start_time_period(TP_2D_CHFRHS)
            isx  = igmem_alloc(nx)
            isy  = igmem_alloc(nx)
            isz  = igmem_alloc(nx)
_IF(rpagrad)
            if (orpagrad) then
               call rhscl_ij(q(ibx),q(iby),q(ibz),q(ieval),
     +                       q(isx),q(isy),q(isz))
               call rhscl_ab(q(ibx),q(iby),q(ibz),q(ieval),
     +                       q(isx),q(isy),q(isz))
            endif
_ENDIF
            call rhscl(q(ieps),q(ibx),q(iby),q(ibz),q(ieval),
     +                 q(isx),q(isy),q(isz))
            call gmem_free(isz)
            call gmem_free(isy)
            call gmem_free(isx)
            call rhscl_dft(q,iq)
            call end_time_period(TP_2D_CHFRHS)
         endif
         if (scftyp.eq.oscf) then
            ibase = igmem_alloc_all(maxa)
            call rhsrhf(q(ieps),q(ibx),q(iby),q(ibz),q(ieval),q(ibase))
            call gmem_free(ibase)
         endif
         call gmem_free(ieval)
         call gmem_free(ibz)
         call gmem_free(iby)
         call gmem_free(ibx)
         iso  = igmem_alloc(nw196(5))
         iiso = lenrel(iso-1)+1
         imap = igmem_alloc(lenint(nx))
         iimap= lenrel(imap-1)+1
_IF(rpagrad)
         mnij = nocca*nocca
         mnab = nvirta*nvirta
         if (orpagrad) then
            mnmx = max(mn,mnij,mnab)
         else
            mnmx = mn
         endif
_ELSE
         mnmx = mn
_ENDIF
         iwrk = igmem_alloc(mnmx*(3*nat+1))
         call start_time_period(TP_2D_SYMMRHS)
_IF(rpagrad)
         if (orpagrad) then
            call symrhs_ij(q(iwrk),iblks,skipp,iq(iimap),iq(iiso),
     +                     nshell)
            call symrhs_ab(q(iwrk),iblks,skipp,iq(iimap),iq(iiso),
     +                     nshell)
            call symrhs(q(iwrk),iblks,skipp,iq(iimap),iq(iiso),nshell)
         else
            call symrhs(q(iwrk),iblks,skipp,iq(iimap),iq(iiso),nshell)
         endif
_ELSE
         call symrhs(q(iwrk),iblks,skipp,iq(iimap),iq(iiso),nshell)
_ENDIF
         call end_time_period(TP_2D_SYMMRHS)
         call gmem_free(iwrk)
         call gmem_free(imap)
         call gmem_free(iso)
c
         lenblk = lensec(mn)
_IF(rpagrad)
         if (orpagrad) then
            mnij = nocca*nocca
            mnab = nvirta*nvirta
            iblku = iblks + np*lenblk 
     +            + 3*nat*(lensec(mnij)+lensec(mnab))
         else
            iblku = iblks + np*lenblk
         endif
_ELSE
         iblku = iblks + np*lenblk
_ENDIF
         lstop = .false.
c
c        solve linear equations
c
         ogeompert_save = ogeompert
         ogeompert = .true.
         call start_time_period(TP_2D_CHFDRV)
         call chfdrv(q(ieps),lstop,skipp)
         call end_time_period(TP_2D_CHFDRV)
         ogeompert = ogeompert_save
         call gmem_free(ieps)
      end if
c
      if (lstop) then
         call revise
         write (iwr,6040)
         call timana(22)
         call clenms('stop')
      else
         iso  = igmem_alloc(nw196(5))
         iiso = lenrel(iso-1)+1
         iwrk = igmem_alloc(3*mn*(nat+1))
         call start_time_period(TP_2D_SYMMU)
         call symmu(q(iwrk),iblku,skipp,iq(iiso),nshell)
         call end_time_period(TP_2D_SYMMU)
         call gmem_free(iwrk)
         call gmem_free(iso)
c
c     perturbed density matrices
c
         iwrk = igmem_alloc(2*nx+mn)
         call start_time_period(TP_2D_PDENS)
         call pdens(q(iwrk),lstop)
         call end_time_period(TP_2D_PDENS)
         call gmem_free(iwrk)
         call start_time_period(TP_2D_PFOCK)
         if (scftyp.eq.closed) then
            call pfockc(q)
            call pdksmc(q,iq)
         endif
         if (scftyp.eq.oscf) call pfocko(q)
         call end_time_period(TP_2D_PFOCK)
         call revise
         call clredx
         call delfil(nofile(1))
         call timana(22)
      end if
_IF(ccpdft)
      ierror = CD_reset_2e()
_ENDIF
 6010 format (/' solve chf equations for nuclear motions')
 6020 format (/1x,'oscf chf equations only work with',
     +        ' canonicalisation 2.0, 0.0, -2.0'/1x,
     +        '------     see manual for details --------')
 6030 format (//' insufficient store for gcphf ( gderci ) ')
 6040 format (//1x,'insufficient time to finish chf equations'//1x,
     +        'restart job'//)
      end
_ENDIF
_IFN(secd_parallel)
      subroutine pdksmc(q,iq)
      implicit none
c
c     Add the DFT wavefunction contribution to the perturbed Fock
c     matrix
c
c     Parameters:
c
INCLUDE(common/sizes)
      integer m8
      parameter (m8=8)
c
c     Input:
c
INCLUDE(common/mapper)
INCLUDE(common/infoa)
INCLUDE(common/atmblk)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/cndx40)
INCLUDE(common/mp2grd)
c
c     Workspace:
c
      integer iq(*)
      REAL q(*)
c
c     Local:
c
      integer ibt, ibd, ltri, iatms,iiatms, iblok, inull
      integer nat3, i, j, k, l, ierror, n, m, lennew
      integer ida, ifa, icc, ida_t
      integer ij, ija
      integer ntot, nnow
      character *6 fnm
      character *6 snm
c
c     Functions:
c
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/gmempara)
      integer lensec
      integer igmem_null
      integer igmem_alloc_inf, lenrel
      data fnm/'cphf.m'/
      data snm/'pdksmc'/
c
c     Code:
c
      if (.not.CD_active()) return
      inull = igmem_null()
c
      if (opg_pertbns_sep) then
c
c        Do everything in batches of 1 coordinate at a time
c        if this code works we should always use it just with 
c        different batch sizes...
c
         ltri = ikyp(ncoorb)
         nat3 = 3*nat
         ntot = 1
         ida = igmem_alloc_inf(ltri*ntot,fnm,snm,
     &                         'pert-density',IGMEM_NORMAL)
         ifa = igmem_alloc_inf(ltri*ntot,fnm,snm,
     &                         'pert-fock',IGMEM_NORMAL)
         icc = igmem_alloc_inf(num*num,fnm,snm,
     &                         'alpha-vectors',IGMEM_NORMAL)
         lennew = lensec(ltri)
         iatms = igmem_alloc_inf(nat3,fnm,snm,
     &                           'perturbations',IGMEM_DEBUG)
         iiatms = lenrel(iatms-1)+1
c
         call secget(isect(8),m8,iblok)
         iblok = iblok + mvadd
         call rdedx(q(icc),num*ncoorb,iblok,ifild)
c
         nnow  = 0
         n     = 0
         m     = 0
         ibd   = iochf(15)
         ibt   = iochf(16)
         ida_t = ida
         do i = 1, nat3
c
c           collect upto ntot perturbed density matrices
c
            n    = n + 1
            nnow = nnow + 1
            iq(iiatms+nnow-1) = (i-1)/3+1
            call rdedx(q(ida_t),ltri,ibd,ifockf)
c
            call dscal(ltri,0.5d0,q(ida_t),1)
            do j = 1, nocca
               q(ida_t-1+j*(j+1)/2) = 0.5d0*q(ida_t-1+j*(j+1)/2)
            enddo
c
            ida_t = ida_t + ltri
            ibd   = ibd   + lennew
c
            if (nnow.eq.ntot.or.i.eq.nat3) then
c
c              got enough perturbed density matrices so do the work
c
               call vclr(q(ifa),1,ltri*nnow)
               ierror = CD_chf_dksm_mo(iq,q,nnow,q(iatms),ncoorb,
     &                  nocca,0,q(icc),q(inull),q(ida),
     &                  q(inull),q(ifa),q(inull),.false.,iwr)
               do j = 1, nnow
                  m = m + 1
                  call rdedx(q(ida),ltri,ibt,ifockf)
                  ija = 0
                  do k = 1, nsa4
                     do l = 1, k
                        ij  = iky(mapie(k)) + mapie(l) - 1
                        q(ida+ij) = q(ida+ij) + q(ifa+(j-1)*ltri+ija)
                        ija = ija + 1
                     enddo
                  enddo
                  call wrt3(q(ida),ltri,ibt,ifockf)
                  ibt = ibt + lennew
               enddo
c
c              reset counters for the next batch
c
               nnow  = 0
               ida_t = ida
            endif
         enddo
         call gmem_free_inf(iatms,fnm,snm,'perturbations')
         call gmem_free_inf(icc,fnm,snm,'alpha-vectors')
         call gmem_free_inf(ifa,fnm,snm,'pert-fock')
         call gmem_free_inf(ida,fnm,snm,'pert-density')
         call revise
         call clredx
         return
      endif
c
      ltri = ikyp(ncoorb)
      nat3 = 3*nat
      ida = igmem_alloc_inf(ltri*nat3,fnm,snm,'pert-density',
     &                      IGMEM_NORMAL)
      ifa = igmem_alloc_inf(ltri*nat3,fnm,snm,'pert-fock',
     &                      IGMEM_NORMAL)
      icc = igmem_alloc_inf(num*num,fnm,snm,'alpha-vectors',
     &                      IGMEM_NORMAL)
      lennew = lensec(ltri)
      iatms = igmem_alloc_inf(nat3,fnm,snm,
     &                        'perturbations',IGMEM_DEBUG)
      iiatms = lenrel(iatms-1)+1
c
      call secget(isect(8),m8,iblok)
      iblok = iblok + mvadd
      call rdedx(q(icc),num*ncoorb,iblok,ifild)
c
      call vclr(q(ifa),1,ltri*nat3)
c
      ibd   = iochf(15)
      ida_t = ida
      n = 0
      do i = 1, nat
         do j = 1, 3
            n = n + 1
            iq(iiatms+n-1) = i
            call rdedx(q(ida_t),ltri,ibd,ifockf)
            ida_t = ida_t + ltri
            ibd   = ibd   + lennew
         enddo
      enddo
      call dscal(ltri*nat3,0.5d0,q(ida),1)
      do i = 1, nat3
         do j = 1, nocca
            q(ida-1+(i-1)*ltri+j*(j+1)/2)
     &      = 0.5d0*q(ida-1+(i-1)*ltri+j*(j+1)/2)
         enddo
      enddo
c
      ierror = CD_chf_dksm_mo(iq,q,nat3,q(iatms),ncoorb,nocca,0,
     &                        q(icc),q(inull),q(ida),q(inull),
     &                        q(ifa),q(inull),.false.,iwr)
c
      ibt = iochf(16)
      do k = 1, nat3
         call rdedx(q(icc),ltri,ibt,ifockf)
         ija = 0
         do i = 1, nsa4
            do j = 1, i
               ij  = iky(mapie(i)) + mapie(j) - 1
               q(icc+ij) = q(icc+ij) + q(ifa+(k-1)*ltri+ija)
               ija = ija + 1
            enddo
         enddo
         call wrt3(q(icc),ltri,ibt,ifockf)
         ibt = ibt + lennew
      enddo
c
      call gmem_free_inf(iatms,fnm,snm,'perturbations')
      call gmem_free_inf(icc,fnm,snm,'alpha-vectors')
      call gmem_free_inf(ifa,fnm,snm,'pert-fock')
      call gmem_free_inf(ida,fnm,snm,'pert-density')
      call revise
      call clredx
      end
_ENDIF
_IFN(secd_parallel)
      subroutine rhscl_dft(q,iq)
      implicit none
c
c     Adds the DFT contributions onto the right-hand-sides.
c
c     Parameters:
c
INCLUDE(common/sizes)
      integer m8
      parameter(m8=8)
c
c     Input:
c
INCLUDE(common/infoa)
INCLUDE(common/cndx41)
INCLUDE(common/atmblk)
INCLUDE(common/common)
INCLUDE(common/mapper)
INCLUDE(common/iofile)
INCLUDE(common/drive_dft)
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
      integer igmem_alloc_inf, igmem_null
      integer lensec, lenrel
c
c     Local:
c
      integer nat3,lennew,newblk,mnblk,is,ib,ic,iblok,iatms,iiatms
      integer ibs,ics,icb,i,j,ierror,iblkb
      integer mu, nu, ni, nd, nk, num2
      integer id, iscr, itmp, inull
      integer m7
      parameter(m7=7)
      character*6 fnm
      character*9 snm
      data fnm/'cphf.m'/
      data snm/'rhscl_dft'/
_IF(ccpdft)
      if (.not.CD_active()) return

      nat3   = nat*3
      lennew = iky(ncoorb)+ncoorb
      newblk = lensec(lennew)
      mnblk  = lensec(mn)
      inull  = igmem_null()
      if (ks_rhs_bas.eq.KS_RHS_MO) then
         is = igmem_alloc_inf(lennew*nat3,fnm,snm,
     &                        'pert-overlap',IGMEM_NORMAL)
         ib = igmem_alloc_inf(mn*nat3,fnm,snm,
     &                        'right-hand-sides',IGMEM_NORMAL)
         ic = igmem_alloc_inf(num*num,fnm,snm,
     &                        'alpha-vectors',IGMEM_NORMAL)
c
c        Get the MO-coefficients
c
         call secget(isect(8),m8,iblok)
         iblok = iblok + mvadd
         call rdedx(q(ic),num*ncoorb,iblok,ifild)
c
c        Get the derivative overlap matrices
c
         ibs = iochf(14)
         ics = is
         do i = 1, nat3
            call rdedx(q(ics),lennew,ibs,ifockf)
            ics = ics + lennew
            ibs = ibs + newblk
         enddo
c
c        Calculate the RHS contributions
c
         iatms = igmem_alloc_inf(nat3,fnm,snm,
     &                           'perturbations',IGMEM_DEBUG)
         iiatms = lenrel(iatms-1)+1
         do i = 1, nat
            iq(iiatms+3*(i-1)+0) = i
            iq(iiatms+3*(i-1)+1) = i
            iq(iiatms+3*(i-1)+2) = i
         enddo
         call vclr(q(ib),1,mn*nat3)
         ierror = CD_chf_rhs_mo(iq,q,nat3,iq(iiatms),ncoorb,nocca,0,
     &                          q(ic),q(inull),q(is),q(inull),
     &                          q(ib),q(inull),.false.,iwr)
         call gmem_free_inf(iatms,fnm,snm,'perturbations')
c
c        Add the DFT RHS contributions onto the Hartree-Fock parts
c
         iblkb = iblks
         icb = ib
         do i = 1, nat3
            call rdedx(q(ic),mn,iblkb,ifils)
            do j = 0, mn-1
               q(ic+j)=q(ic+j)+q(icb+j)
            enddo
            call wrt3(q(ic),mn,iblkb,ifils)
            iblkb = iblkb + mnblk
            icb   = icb   + mn
         enddo
         call clredx
         call gmem_free_inf(ic,fnm,snm,'alpha-vectors')
         call gmem_free_inf(ib,fnm,snm,'right-hand-sides')
         call gmem_free_inf(is,fnm,snm,'pert-overlap')
      else if (ks_rhs_bas.eq.KS_RHS_AO) then
         num2 = num*num
         ib = igmem_alloc_inf(num2*nat3,fnm,snm,'right-hand-side-ao',
     &                        IGMEM_NORMAL)
         is = igmem_alloc_inf(num2*nat3,fnm,snm,'pert-overlap-ao',
     &                        IGMEM_NORMAL)
         ic = igmem_alloc_inf(num2,fnm,snm,'vectors',
     &                        IGMEM_NORMAL)
c
c        get the mo-coefficients
c
         call secget(isect(8),m8,iblok)
         iblok = iblok + mvadd
         call rdedx(q(ic),num*ncoorb,iblok,ifild)
c
c        load the derivative overlap matrices and transform them
c        to AO basis.
c
         itmp = igmem_alloc_inf(lennew,fnm,snm,'temp',IGMEM_DEBUG)
         iscr = igmem_alloc_inf(num,fnm,snm,'scratch',IGMEM_DEBUG)
         call vclr(q(is),1,num*num*nat3)
         ibs = iochf(14)
         do i = 1, nat3
            call rdedx(q(itmp),lennew,ibs,ifockf)
            ibs = ibs + newblk
            do ni = 1, nocc
               call vclr(q(iscr),1,num)
               do nu = 1, num
                  do nk = 1, nocc
                     q(iscr-1+nu)=q(iscr-1+nu)
     &                           -0.5d0*q(ic-1+nu+(nk-1)*num)
     &                           *q(itmp-1+iky(max(ni,nk))+min(ni,nk))
                  enddo
               enddo
               do nu = 1, num
                  do mu = 1, num
                     q(is-1+mu+(nu-1)*num+(i-1)*num2) 
     &               = q(is-1+mu+(nu-1)*num+(i-1)*num2)
     &               + q(ic-1+nu+(ni-1)*num)*q(iscr-1+mu)
     &               + q(ic-1+mu+(ni-1)*num)*q(iscr-1+nu)
                  enddo
               enddo
            enddo
         enddo
         call gmem_free_inf(iscr,fnm,snm,'scratch')
         call gmem_free_inf(itmp,fnm,snm,'temp')
         call gmem_free_inf(ic,fnm,snm,'vectors')
c
c        load the density matrix
c
         id = igmem_alloc_inf(lennew,fnm,snm,'density',IGMEM_NORMAL)
         call secget(isect(7),m7,iblok)
         call rdedx(q(id),nx,iblok,ifild)
c
c        call DFT module
c
         iatms = igmem_alloc_inf(nat3,fnm,snm,'perturbations',
     &                           IGMEM_DEBUG)
         iiatms = lenrel(iatms-1)+1
         do i = 1, nat
            iq(iiatms+3*(i-1)+0) = i
            iq(iiatms+3*(i-1)+1) = i
            iq(iiatms+3*(i-1)+2) = i
         enddo
         call vclr(q(ib),1,num2*nat3)
         ierror = CD_chf_rhs_ao(iq,q,nat3,iq(iiatms),q(id),q(inull),
     &            q(is),q(inull),q(ib),q(inull),.false.,iwr)
         call gmem_free_inf(iatms,fnm,snm,'perturbations')
         call gmem_free_inf(id,fnm,snm,'density')
         call gmem_free_inf(is,fnm,snm,'pert-overlap-ao')
c
c        load the vectors again
c
         ic = igmem_alloc_inf(num*ncoorb,fnm,snm,'vectors',IGMEM_NORMAL)
         call secget(isect(8),m8,iblok)
         iblok = iblok + mvadd
         call rdedx(q(ic),num*ncoorb,iblok,ifild)
c
c        transform and store DFT results
c
         itmp = igmem_alloc_inf(mn,fnm,snm,'temp',IGMEM_DEBUG)
         iscr = igmem_alloc_inf(num,fnm,snm,'scratch',IGMEM_DEBUG)
         iblkb = iblks
         do i = 1, nat3
            call rdedx(q(itmp),mn,iblkb,ifils)
            do ni = 1, nocc
               call vclr(q(iscr),1,num)
               do mu = 1, num
                  do nu = 1, num
                     q(iscr-1+mu) = q(iscr-1+mu)
     &               + q(ic-1+nu+(ni-1)*num)*
     &                 q(ib-1+mu+(nu-1)*num+(i-1)*num2)
                  enddo
               enddo
               do nd = 1, nvirt
                  do mu = 1, num
                     q(itmp-1+ni+(nd-1)*nocc) = q(itmp-1+ni+(nd-1)*nocc)
     &               + q(ic-1+mu+(nocc+nd-1)*num)*q(iscr-1+mu)
                  enddo
               enddo
            enddo
            call wrt3(q(itmp),mn,iblkb,ifils)
            iblkb = iblkb + mnblk
         enddo
         call clredx
         call gmem_free_inf(iscr,fnm,snm,'scratch')
         call gmem_free_inf(itmp,fnm,snm,'temp')
         call gmem_free_inf(ic,fnm,snm,'vectors')
         call gmem_free_inf(ib,fnm,snm,'right-hand-side-ao')

      else if (ks_rhs_bas.eq.KS_RHS_AOMO) then
         call caserr('rhscl_dft: KS_RHS_AOMO implemented yet!')
      else
         call caserr('rhscl_dft: invalid option')
      endif
_ENDIF
      end
_ENDIF
      subroutine efdens(u,d)
c
c   constructs first order density matrices from electric-field
c   perturbed orbitals
c  ------------------------------------------------------------
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension u(*),d(*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
      common/mpshl/ns(maxorb)
INCLUDE(common/ghfblk)
INCLUDE(common/mapper)
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
INCLUDE(common/prnprn)
c
      character *8 grhf
      data grhf/'grhf'/
c
      length = lensec(mn)
      iblku = iblks + np*length
      nsoc = noccb - nocca
      ndp1 = nocca + 1
      nsp1 = noccb + 1
      if (odebug(3)) write (iwr,6010)
      nw = iky(ncoorb+1)
      iblll = lensec(nw)
      icomp = 31
      do 110 npert = 1 , 9
         if (.not.(opskip(npert))) then
            call rdedx(u,mn,iblku,ifils)
            iblku = iblku + length
            do 20 j = 1 , nw
               d(j) = 0.0d0
 20         continue
            if (scftyp.eq.grhf) then
               nr = 0
               do 40 i = 1 , nsa4
                  do 30 j = 1 , i
                     if (ns(i).ne.ns(j)) then
                        nr = nr + 1
                        ij = iky(mapie(i)) + mapie(j)
                        d(ij) = u(nr)*(fjk(ns(j))-fjk(ns(i)))
                     end if
 30               continue
 40            continue
            else
               if (nsoc.ne.0 .and. nocca.ne.0) then
                  do 60 i = ndp1 , noccb
                     do 50 j = 1 , nocca
                        ij = iky(mapie(i)) + mapie(j)
                        mt = (i-nocca-1)*nocca + j
                        d(ij) = u(mt)
 50                  continue
 60               continue
               end if
               if (nocca.ne.0) then
                  do 80 i = nsp1 , nsa4
                     do 70 j = 1 , nocca
                        ij = iky(mapie(i)) + mapie(j)
                        mt = (i-nocca-1)*nocca + j
                        d(ij) = u(mt) + u(mt)
 70                  continue
 80               continue
               end if
               if (nsoc.ne.0) then
                  do 100 i = nsp1 , nsa4
                     do 90 j = ndp1 , noccb
                        ij = iky(mapie(i)) + mapie(j)
                        mt = nocca*nvirta + (i-nsoc-1)*nsoc + j - nocca
                        d(ij) = u(mt)
 90                  continue
 100              continue
               end if
            end if
            call secput(isect(icomp),icomp,iblll,iblok)
            lds(isect(icomp)) = nw
            if (odebug(3)) call prtris(d,ncoorb,iwr)
            call wrt3(d,nw,iblok,ifild)
         end if
         icomp = icomp + 1
 110  continue
      call revind
      call revise
      call clredx
      return
 6010 format (//1x,'total perturbed density matrices in mo basis')
      end
_IFN(secd_parallel)
      subroutine pdens(ss,lstop)
c
c    perturbed density matrices (nuclear motions) in m.o. basis
c
      implicit REAL  (a-h,o-z)
      logical lstop
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
      common/mpshl/ns(maxorb)
INCLUDE(common/ghfblk)
INCLUDE(common/infoa)
      dimension ss(*)
      character *8 grhf,oscf
INCLUDE(common/mapper)
INCLUDE(common/prnprn)
_IF(rpagrad)
INCLUDE(common/rpadcom)
_ENDIF
      logical open
      data grhf/'grhf'/
      data oscf/'oscf'/
      data zero/0.0d0/
      open = scftyp.eq.oscf
c
c
      if (odebug(3)) write (iwr,6010)
      iblll = lensec(mn)
_IF(rpagrad)
      if (orpagrad) then
         mnij = nocca*nocca
         mnab = nvirt*nvirt
         iblku = iblks + iblll*np + 3*nat*(lensec(mnij)+lensec(mnab))
      else
         iblku = iblks + iblll*np
      endif
_ELSE
      iblku = iblks + iblll*np
_ENDIF
      if (lstop) then
c
c     dump because running out of time
c
         iochf(15) = iochf(1)
         iposd = iochf(1)
         do 20 n = 1 , npfin
            call rdedx(ss,mn,iblku,ifils)
            call wrt3(ss,mn,iposd,ifockf)
            iblku = iblku + iblll
            iposd = iposd + iblll
 20      continue
         npstar = npfin
         irest = 1
         return
      else
c
c
         nsoc = noccb - nocca
         ndpls1 = nocca + 1
         ntpls1 = noccb + 1
         nw = iky(ncoorb+1)
c
c
         iposs = iochf(14)
         iblls = lensec(nw)
c
c     output to section 15 of fockfile.
c     overlap matrix derivatives (m.o. basis) on section 14
c     perturbed wavefunctions on scratchfile
c
         iochf(15) = iochf(1)
         iposd = iochf(15)
         iposdo = iposd + 3*nat*iblls
         call wrt3z(iposd,ifockf,3*nat*iblls)
         if (open) call wrt3z(iposd,ifockf,3*nat*iblls)
         nu = nx + nx
         nopen = nu + mn
         do 170 i = 1 , nat
            do 160 j = 1 , 3
               call rdedx(ss,nw,iposs,ifockf)
               call rdedx(ss(nu+1),mn,iblku,ifils)
               iposs = iposs + iblls
               iblku = iblku + iblll
               do 30 k = 1 , nw
                  if (open) ss(nopen+k) = zero
                  ss(nx+k) = zero
 30            continue
               if (scftyp.eq.grhf) then
                  nr = 0
                  kl = 0
                  do 50 k = 1 , nsa4
                     do 40 l = 1 , k
                        kl = iky(mapie(k)) + mapie(l)
                        ss(nx+kl) = -0.5d0*ss(kl)*
     +                              (fjk(ns(k))+fjk(ns(l)))
                        if (ns(k).ne.ns(l)) then
                           nr = nr + 1
c                          ssss = ss(nx+kl)
                           ss(nx+kl) = ss(nx+kl) + 0.5d0*ss(nu+nr)
     +                                  *(fjk(ns(l))-fjk(ns(k)))
                        end if
 40                  continue
 50               continue
               else
                  if (nocca.ne.0) then
                     do 70 k = 1 , nocca
                        do 60 l = 1 , k
                           kl = iky(mapie(k)) + mapie(l)
                           ss(nx+kl) = -2.0d0*ss(kl)
 60                     continue
 70                  continue
                  end if
                  if (nsoc.ne.0 .and. nocca.ne.0) then
                     do 90 k = ndpls1 , noccb
                        do 80 l = 1 , nocca
                           kl = iky(mapie(k)) + mapie(l)
                           mt = (k-nocca-1)*nocca + l
                           if (open) ss(nopen+kl) = -ss(kl) - ss(nu+mt)
                           ss(nx+kl) = -ss(kl) + ss(nu+mt)
 80                     continue
 90                  continue
                  end if
                  if (nsoc.ne.0) then
                     do 110 k = ndpls1 , noccb
                        do 100 l = ndpls1 , k
                           kl = iky(mapie(k)) + mapie(l)
                           if (open) ss(nopen+kl) = -ss(kl)
                           ss(nx+kl) = -ss(kl)
 100                    continue
 110                 continue
                  end if
                  if (nocca.ne.0) then
                     do 130 k = ntpls1 , num
                        do 120 l = 1 , nocca
                           kl = iky(mapie(k)) + mapie(l)
                           mt = (k-nocca-1)*nocca + l
                           ss(nx+kl) = 2.0d0*ss(nu+mt)
 120                    continue
 130                 continue
                  end if
                  if (nsoc.ne.0) then
                     do 150 k = ntpls1 , num
                        do 140 l = ndpls1 , noccb
                           kl = iky(mapie(k)) + mapie(l)
                           mt = nocca*nvirta + (k-nsoc-1)*nsoc + l -
     +                          nocca
                           if (open) ss(nopen+kl) = ss(nu+mt)
                           ss(nx+kl) = ss(nu+mt)
 140                    continue
 150                 continue
                  end if
               end if
               if (odebug(3)) call prtris(ss(nx+1),ncoorb,iwr)
               call wrt3(ss(nx+1),nw,iposd,ifockf)
               if (open) call wrt3(ss(nopen+1),nw,iposdo,ifockf)
               iposd = iposd + iblls
               if (open) iposdo = iposdo + iblls
 160        continue
 170     continue
         iochf(1) = max(iposd,iposdo)
         call clredx
         irest = 0
c
c
         return
      end if
 6010 format (//1x,'total perturbed density matrices in mo basis')
      end
      subroutine chfdrv(eps,lstop,skipp)
      implicit REAL  (a-h,o-z)
c
c     driving routine for c.h.f.
c     calls chfeqs or chfeq/chfeqv
c
      logical lstop,skipp
      dimension skipp(*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/vcore)
INCLUDE(common/gmempara)
INCLUDE(common/ccpdft.hf77)
      logical scalar
      common/rpaoptions/scalar
c
      character *8 open
      character *6 fnm
      character *6 snm
      dimension eps(mn)
      data open/'open'/
      data fnm/'cphf.m'/
      data snm/'chfdrv'/
c
c
      npstar = 0
      npfin = np
      maxmem = igmem_max_memory()
      memovh = igmem_overhead()
      reqmem = 4*mn+2*mn*mn
      if (mn.le.250 .and. reqmem.lt.maxmem. and. scalar .and. 
     &    .not.CD_active()) then
c
c      use in-core solution
c
         i1 = igmem_alloc_inf(mn,fnm,snm,'b',IGMEM_DEBUG)
         i2 = igmem_alloc_inf(mn,fnm,snm,'cc',IGMEM_DEBUG)
         i3 = igmem_alloc_inf(mn,fnm,snm,'wks1',IGMEM_DEBUG)
         i4 = igmem_alloc_inf(mn,fnm,snm,'wks2',IGMEM_DEBUG)
         i5 = igmem_alloc_inf(mn*mn,fnm,snm,'alpha',IGMEM_DEBUG)
         i6 = igmem_alloc_inf(mn*mn,fnm,snm,'aa',IGMEM_DEBUG)
c
         call chfeqs(eps,Q(i1),Q(i2),Q(i3),
     +               Q(i4),Q(i5),Q(i6),mn,skipp)
c
         call gmem_free_inf(i6,fnm,snm,'aa')
         call gmem_free_inf(i5,fnm,snm,'alpha')
         call gmem_free_inf(i4,fnm,snm,'wks2')
         call gmem_free_inf(i3,fnm,snm,'wks1')
         call gmem_free_inf(i2,fnm,snm,'cc')
         call gmem_free_inf(i1,fnm,snm,'b')
c
       else
c
c       use iterative method
c
         maxc = 50
         if ((mp2 .or. mp3) .and. scftyp.eq.open) then
c
c         use older chfeq
c
            i1 = igmem_alloc_inf(mn,fnm,snm,'b',IGMEM_DEBUG)
            i2 = igmem_alloc_inf(mn,fnm,snm,'utotal',IGMEM_DEBUG)
            i3 = igmem_alloc_inf(mn,fnm,snm,'uold',IGMEM_DEBUG)
            i4 = igmem_alloc_inf(mn*maxc,fnm,snm,'au',IGMEM_NORMAL)
            i5 = igmem_alloc_inf(mn*maxc,fnm,snm,'u',IGMEM_NORMAL)
            write (iwr,*) 'using older chfeq'
            call chfeq(Q(1),eps,Q(i1),Q(i2),
     +                 Q(i3),Q(i4),Q(i5),
     +                 maxc,lstop,skipp)
            call gmem_free_inf(i5,fnm,snm,'u')
            call gmem_free_inf(i4,fnm,snm,'au')
            call gmem_free_inf(i3,fnm,snm,'uold')
            call gmem_free_inf(i2,fnm,snm,'utotal')
            call gmem_free_inf(i1,fnm,snm,'b')
            if (lstop) call clenms('run out of time')
         else
 20         npx = npfin - npstar
            i1 = 0
            i2 = i1 + mn*npx        + memovh
            i3 = i2 + mn*npx        + memovh
            i4 = i3 + maxc*npx      + memovh
            i5 = i4 + maxc*npx      + memovh
            i6 = i5 + maxc*npx      + memovh
            i7 = i6 + maxc*maxc*npx + memovh
            i8 = i7 + npx           + memovh
            ileft = maxmem - i8 - memreq_chfeqv(Q(1),skipp,npx)
     &            - memovh
c
c           irmax is the number of columns of the CPHF matrix that can
c           be loaded into core at a time. The whole matrix has 
c           dimension mn*mn.
c
            irmax = ileft/mn
_IF1()c      write(iwr,*)' i0,i1,i2,i3,i4,i5,i6,i7,maxq'
_IF1()c      write(iwr,*)i0,i1,i2,i3,i4,i5,i6,i7,maxq
_IF1()c      write(iwr,*)' mn,ileft,irmax,npstar,npfin,npx,maxc'
_IF1()c      write(iwr,*) mn,ileft,irmax,npstar,npfin,npx,maxc
            if (irmax.ge.mn) then
c
c              We can load the whole matrix in core so that is fine.
c
               irmax = mn
            else if (irmax.lt.10) then
c
c              We want to be able to load at least 10 columns at a 
c              time. So keep reducing the number of systems of linear
c              equations until we have enough memory left to do this.
c              If we cannot get 10 columns in core then abort the
c              calculation.
c
               npfin = npfin - 1
               if (npfin.gt.npstar) go to 20
               nreq1 = i8 + mn*10 + memovh
               nreq2 = i8 + mn*32 + memovh
               write (iwr,6010) maxmem , nreq1 , nreq2
               call caserr('insufficient core')
               go to 99999
            else if (irmax.lt.32) then
c
c              We ideally want to be able to load 32 columns at a time.
c              So keep reducing the number of systems of linear 
c              equations until we have enough memory to do this or 
c              until there is 1 system left.
c
               if ((npfin-1).gt.npstar) then
                  npfin = npfin - 1
                  go to 20
               endif
            end if
            i1 = igmem_alloc_inf(mn*npx,fnm,snm,'au',IGMEM_DEBUG)
            i2 = igmem_alloc_inf(mn*npx,fnm,snm,'u',IGMEM_DEBUG)
            i3 = igmem_alloc_inf(maxc*npx,fnm,snm,'b',IGMEM_DEBUG)
            i4 = igmem_alloc_inf(maxc*npx,fnm,snm,'cc',IGMEM_DEBUG)
            i5 = igmem_alloc_inf(maxc*npx,fnm,snm,'uu',IGMEM_DEBUG)
            i6 = igmem_alloc_inf(maxc*maxc*npx,fnm,snm,'uau',
     +                           IGMEM_DEBUG)
            i7 = igmem_alloc_inf(irmax*mn,fnm,snm,'work',IGMEM_DEBUG)
            i8 = igmem_alloc_inf(npx,fnm,snm,'oconv',IGMEM_DEBUG)
            call chfeqv(Q(1),eps,Q(i1),Q(i2),
     +                  Q(i7),Q(i3),Q(i4),
     +                  Q(i5),Q(i6),
     +                  maxc,skipp,npx,irmax,Q(i8))
            call gmem_free_inf(i8,fnm,snm,'oconv')
            call gmem_free_inf(i7,fnm,snm,'work')
            call gmem_free_inf(i6,fnm,snm,'uau')
            call gmem_free_inf(i5,fnm,snm,'uu')
            call gmem_free_inf(i4,fnm,snm,'cc')
            call gmem_free_inf(i3,fnm,snm,'b')
            call gmem_free_inf(i2,fnm,snm,'u')
            call gmem_free_inf(i1,fnm,snm,'au')
            if (npfin.lt.np) then
               npstar = npfin
               npfin = np
               go to 20
            end if
         end if
      end if
99999 return
 6010 format (//1x,'insufficient store for chf equations'//1x,
     +        'store available ',i8/1x,'required - at least ',i8,
     +        ' and preferably ',i8)
      end
_ENDIF
      subroutine derlag(q,xerg,yerg,f)
c
c      derivative lagrangian   (integral derivatives only)
c      general scf case
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      common/mpshl/inshel(maxorb)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
INCLUDE(common/ghfblk)
INCLUDE(common/prnprn)
c
      dimension f(11),xerg(11,11),yerg(11,11),q(2)
      call bfnshl(inshel,nsa4)
      nat3 = nat*3
      nfok = nat3 + nat3*njk*2
      i1 = igmem_alloc(num*num)
      i2 = igmem_alloc(nfok*nx)
      call search(iochf(13),ifockf)
      ij = i2
      do 20 n = 1 , nfok
         call reads(q(ij),nx,ifockf)
         call actmot(q(ij),nsa4,mapie,iky)
         ij = ij + nx
 20   continue
      iochf(17) = iochf(1)
      iochf(1) = iochf(1) + lensec(nsa4*nsa4)*nat3
      call search(iochf(17),ifockf)
      lenbig = nx*nat3*2
      do 80 n = 1 , nat3
         call vclr(q(i1),1,num*num)
         ij = i2 + (n-1)*nx
         do 40 i = 1 , nsa4
            do 30 j = 1 , i
               q(i1-1+(j-1)*nsa4+i) = q(ij)*f(inshel(i))*0.5d0
               q(i1-1+(i-1)*nsa4+j) = q(ij)*f(inshel(j))*0.5d0
               ij = ij + 1
 30         continue
 40      continue
         ij = i2 + nx*nat3 + (n-1)*nx
         do 70 i = 1 , nsa4
            do 60 j = 1 , i
               ijj = ij
               ijk = ij + nx*nat3
               do 50 k = 1 , njk
                  q(i1-1+(j-1)*nsa4+i) 
     +            = q(i1-1+(j-1)*nsa4+i) + xerg(inshel(i),k)
     +                           *q(ijj) + yerg(inshel(i),k)*q(ijk)
                  if (i.ne.j) then
                     q(i1-1+(i-1)*nsa4+j) 
     +               = q(i1-1+(i-1)*nsa4+j) + xerg(inshel(j),k)
     +                              *q(ijj) + yerg(inshel(j),k)*q(ijk)
                  end if
                  ijj = ijj + lenbig
                  ijk = ijk + lenbig
 50            continue
               ij = ij + 1
 60         continue
 70      continue
         if (odebug(16)) call prsqm(q(i1),nsa4,nsa4,nsa4,iwr)
         call wrt3s(q(i1),nsa4*nsa4,ifockf)
 80   continue
      call gmem_free(i2)
      call gmem_free(i1)
c
      return
      end
      subroutine effock(q)
c
c     perturbed fock operators for electric field perturbations
c
      implicit REAL  (a-h,o-z)
      logical mpir,mpol,mpir0,mpir1
INCLUDE(common/sizes)
      common/blkin/g(510),nword
      common/craypk/labs(1360)
INCLUDE(common/infoa)
      dimension q(*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/mapper)
      common/maxlen/maxq
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
      character *8 dipdmp,polmp2,infrar
INCLUDE(common/prnprn)
INCLUDE(common/atmblk)
      data        half /       0.5d0/
      data dipdmp /'dipder'/,infrar/'infrared'/
      data polmp2/'polariza'/
      ltri = ikyp(ncoorb)
      length = lensec(ltri)
      icomp = 31
      ifout = 70
c
      np = 0
      maxp = 9
      if (mp2) maxp = 3
      do 20 i = 1 , maxp
         if (ione(i+3).ne.0) np = np + 1
 20   continue
      mpir0 = runtyp.eq.dipdmp .and. mp2
      mpir1 = runtyp.eq.infrar .and. mp2
      mpir = mpir0 .or.mpir1
      mpol = runtyp.eq.polmp2 .and. mp2
      if (mpir .or. mpol) then
         npert = 3
c
c    >>>>> eventually npert = np
c
         nat3 = 3*nat
         nij = nocca*(nocca+1)/2
         nab = nvirta*(nvirta+1)/2
c        ntri = ncoorb*(ncoorb+1)/2
         mpblk(1) = 1
         mpblk(2) = mpblk(1) + lensec(nat3*nat3)
         mpblk(3) = mpblk(2) + lensec(nij*nab)
         mpblk(4) = mpblk(3) + lensec(nij*nab)
         mpblk(5) = mpblk(4) + lensec(ncoorb)
         mpblk(6) = mpblk(5) + lensec(ncoorb*ncoorb*npert)
         mpblk(7) = mpblk(6) + lensec(ncoorb*ncoorb*npert)
         call wrt3z(1,1,mpblk(7))
      end if
c
      call setsto(1360,0,labs)
c
      do 100 n = 1 , 9
         if (.not.(opskip(n))) then
            if (odebug(4)) write (iwr,6010)
c
c     get position of perturbed density matrix on dumpfile
c
            jtype = 0
            call secget(isect(icomp),jtype,iblok)
            call rdedx(q(ltri+1),lds(isect(icomp)),iblok,ifild)
            ija = 0
            do 40 i = 1 , nsa4
               do 30 j = 1 , i
                  ija = ija + 1
                  ij = iky(mapie(i)) + mapie(j)
                  q(ija) = half*q(ij+ltri)
 30            continue
 40         continue
            call vclr(q(ltri+1),1,ltri)
            do 50 i = 1 , ncoorb
               ii = iky(i+1)
               q(ii) = q(ii)*0.5d0
 50         continue
c     total density matrix in q(1)
c
c     scan 2-electron integrals
c
            do 70 i = 1 , mmfile
               iunit = nufile(i)
               call search(kblk(i),iunit)
               call find(iunit)
 60            call get(g,m)
               if (m.ne.0) then
                  if (o255i) then
                     call sgmata(q(ltri+1),q(1))
                  else
                     call sgmata_255(q(ltri+1),q(1))
                  endif
                  call find(iunit)
                  go to 60
               end if
 70         continue
c     get one-electron integrals , and form complete
c     perturbed fock matrix
c
            jtype = 0
            call secget(ipsec(n),jtype,iblok)
            call rdedx(q(1),lds(ipsec(n)),iblok,ifild)
            ij = ltri
            do 90 i = 1 , nsa4
               do 80 j = 1 , i
                  ij = ij + 1
                  ij1 = iky(mapie(i)) + mapie(j)
                  q(ij1) = q(ij1) + q(ij)
 80            continue
 90         continue
c
c     store on the fockfile (ed1)
c
            call secput(isect(ifout),ifout,length,iblok)
            lds(isect(ifout)) = ltri
            call wrt3(q,ltri,iblok,ifild)
            if (odebug(4)) call prtris(q,ncoorb,iwr)
         end if
         icomp = icomp + 1
         ifout = ifout + 1
 100  continue
      call revind
      if (mpir .or. mpol) then
c
c    >>>>>>>>>>>> note npert = 3 temporarily, but
c    >>>>>>>>>>>> but should be pert = np to get
c    >>>>>>>>>>>> quadrupole perturbations as well
c
         npert = 3
         i1 = ltri + 1
         i2 = i1 + ncoorb
         i3 = i2 + ncoorb*ncoorb*npert
         i4 = i3 + ncoorb*ncoorb*npert
         if (i4.gt.maxq) call caserr('insufficient core for makeuf')
         call umatef(q(1),q(i1),q(i2),q(i3),ltri,ncoorb,npert)
      end if
      return
 6010 format (//1x,'perturbed total fock matrices')
      end
_IFN(secd_parallel)
      subroutine pfockc(q)
c
c     adds derivative wavefunction term to derivative integral
c     term to make complete derivative of fock operator
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/blkin/g(510),nword
      common/craypk/labs(1)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
      common/maxlen/maxq
INCLUDE(common/symtry)
      dimension q(*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/prnprn)
INCLUDE(common/mapper)
      nat3 = nat*3
      ltri = ikyp(ncoorb)
      ibm1 = kblk(1)
      ibm2 = nblk(1)
      idevm = nufile(1)
      length = lensec(ltri)
      ibt = iochf(1)
c
c     perturbed density matrices at section 15
c     derivatives of integrals at section 13
c     complete fock matrix output at section 16 (m.o. basis)
c
      ibh = iochf(13)
      ibd = iochf(15)
      iochf(16) = ibt
c
c      modifications for multipass version
c
      mfok = igmem_max_memory()/(ltri+ltri)
c     mfok is maximum no. of fock matrices per pass , therefore
      npass = (nat3-1)/mfok + 1
      nadd = min(nat3,mfok)
      mi = 1
      ma = nadd
      mzero = igmem_alloc(nadd*ltri)
      mhalf = igmem_alloc(nadd*ltri)
c     mtwo = mhalf + mhalf
c     mthalf = mtwo + mhalf
c     write(iwr,*)' nadd,mi,ma,mhalf',nadd,mi,ma,mhalf
      call setsto(1360,0,labs)
      do 150 ipass = 1 , npass
         i = mhalf 
c    read in batch of density matrices
         do 20 n = mi , ma
            call rdedx(q(i),ltri,ibd,ifockf)
            i = i + ltri
            ibd = ibd + length
 20      continue
c
c     map to active only
c
         ija = 0
         do 50 i = 1 , nsa4
            do 40 j = 1 , i
               ija = ija + 1
               ij = iky(mapie(i)) + mapie(j)
               k = mzero-1
               l = mhalf-1
_IF1(ct)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
               do 30 n = mi , ma
                  q(ija+k) = 0.5d0*q(ij+l)
                  k = k + ltri
                  l = l + ltri
 30            continue
 40         continue
 50      continue
c
c     multiply diagonal of density matrix by 0.5
c
         do 70 i = 1 , nsa4
            ii = mzero+iky(i+1)-1
            k = 0
            do 60 n = mi , ma
               q(ii+k) = 0.5d0*q(ii+k)
               k = k + ltri
 60         continue
 70      continue
         call vclr(q(mhalf),1,ltri*nadd)
c     construct fock matrix in q(mhalf)
c
         call search(ibm1,idevm)
         call find(idevm)
         do 80 ib = ibm1 , ibm2
            call get(g,nw)
            if (nword.eq.0) go to 90
            if (nw.eq.0) go to 90
            call find(idevm)
            call sgmatm(q(mhalf),q(mzero),nadd,ltri)
 80      continue
c
c     get term involving integral derivatives
c     and form complete derivative fock matrix
c
 90      i = mzero
         do 100 n = mi , ma
            call rdedx(q(i),ltri,ibh,ifockf)
            i = i + ltri
            ibh = ibh + length
 100     continue
         ija = 0
         do 130 i = 1 , nsa4
            do 120 j = 1 , i
               ija = ija + 1
               ij = iky(mapie(i)) + mapie(j)
               k = mzero-1
               l = mhalf-1
_IF1(ct)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
               do 110 n = mi , ma
                  q(ij+k) = q(ij+k) + q(ija+l)
                  k = k + ltri
                  l = l + ltri
 110           continue
 120        continue
 130     continue
         i = mzero
         do 140 n = mi , ma
            call wrt3(q(i),ltri,ibt,ifockf)
            if (odebug(4)) then
               write (iwr,6010) n
               call prtris(q(i),ncoorb,iwr)
            end if
            i = i + ltri
            ibt = ibt + length
 140     continue
         mi = mi + nadd
         ma = ma + nadd
         ma = min(ma,nat3)
 150  continue
      iochf(1) = ibt
      call revise
      call clredx
      if(odebug(30)) then
       write (iwr,6020) iochf(13),iochf(14),iochf(15),iochf(16)
      endif
      call gmem_free(mhalf)
      call gmem_free(mzero)
      if (.not.mp2) return
c
      i2 = igmem_alloc(nw196(5))
      i1 = igmem_alloc((nat3+1)*ltri)
      call symfck(q(i1),q(i2),nshell)
      call gmem_free(i1)
      call gmem_free(i2)
c
      i0 = igmem_alloc(ltri)
      i1 = igmem_alloc(ltri)
      i2 = igmem_alloc(ncoorb)
      i3 = igmem_alloc(ncoorb*ncoorb*nat3)
      call umat(q(i0),q(i1),q(i2),q(i3),ltri,ncoorb,nat3)
      call gmem_free(i3)
      call gmem_free(i2)
      call gmem_free(i1)
      call gmem_free(i0)
      call revise
      return
 6010 format (//5x,'perturbed fock matrix in m.o. basis -- perturbation'
     +        ,i6/)
 6020  format(/1x,'hamfile summary'/
     +         1x,'section 13 at block ',i5/
     +         1x,'section 14 at block ',i5/
     +         1x,'section 15 at block ',i5/
     +         1x,'section 16 at block ',i5/)
      end
_ENDIF
      subroutine pfocko(q)
c
c     perturbed density matrices for high-spin open-shell
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/blkin/g(510),nword
INCLUDE(common/infoa)
      dimension q(*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/mapper)
INCLUDE(common/prnprn)
      data zero , half /0.0d0, 0.5d0/
      nat3 = nat*3
      ltri = ikyp(ncoorb)
      ltri0 = igmem_alloc(ltri)
      ltri1 = igmem_alloc(ltri)
      ltri2 = igmem_alloc(ltri)
      ltri3 = igmem_alloc(ltri)
      ibm1 = kblk(1)
      ibm2 = nblk(1)
      idevm = nufile(1)
      length = lensec(ltri)
      ibt = iochf(1)
c
c     perturbed density matrices at section 15
c     derivatives of integrals at section 13
c     complete fock matrix output at section 16 (m.o. basis)
c
      ibh = iochf(13)
      ibd = iochf(15)
      ibdo = ibd + 3*nat*length
      ibk = ibh + 3*nat*length
      iochf(16) = ibt
      do 100 n = 1 , nat3
         call rdedx(q(ltri1),ltri,ibd,ifockf)
c  assume open shell perturbed density matrices are stored
c  after total perturbed density matrices on same section of
c  same file
         call rdedx(q(ltri3),ltri,ibdo,ifockf)
c
c      map active elements only into q(1),q(ltri2+1)
c
         ija = 0
         do 30 i = 1 , nsa4
            do 20 j = 1 , i
               ij = iky(mapie(i)) + mapie(j) - 1
               q(ltri0+ija) = half*q(ij+ltri)
               q(ltri2+ija) = half*q(ij+ltri3)
               ija = ija + 1
 20         continue
 30      continue
_IFN1(iv)         do 40 i = 1 , ncoorb
_IFN1(iv)            ii = iky(i+1)-1
_IFN1(iv)            q(ltri0+ii) = q(ltri0+ii)*0.5d0
_IFN1(iv)            q(ltri2+ii) = q(ltri2+ii)*0.5d0
_IFN1(iv) 40      continue
         do 50 i = 0 , ltri-1
            q(i+ltri1) = zero
            q(i+ltri3) = zero
 50      continue
c  calculate 1/2g:d and put it in q(l+1) - q(2l)
c  calculate 1/2j:do and put it in q(3l+1) - q(4l)
c********************************
c     ibm version of proc2 produces f and k as results.
c
c      the cray version requires the diagonal elements of
c     the density matrices *0.5 and produces f and +k as
c     results.
c
c**********************************
         call search(ibm1,idevm)
         call find(idevm)
         do 60 ib = ibm1 , ibm2
            call get(g,nw)
            if (nword.eq.0) go to 70
            if (nw.eq.0) go to 70
            call find(idevm)
_IF(ccpdft)
_IF(ibm,vax)
            call proc2(q(ltri1),q(ltri0),q(ltri3),q(ltri2),iky,
     +                 1.0d0,.true.,.true.)
_ELSEIF(cray)
            call proc2(q(ltri1),q(ltri0),q(ltri3),q(ltri2))
_ELSE
            call proc2f(q(ltri1),q(ltri0),q(ltri3),q(ltri2),
     +                 1.0d0,.true.,.true.)
_ENDIF
_ELSE
_IF(ibm,vax)
            call proc2(q(ltri1),q(ltri0),q(ltri3),q(ltri2),iky)
_ELSEIF(cray)
            call proc2(q(ltri1),q(ltri0),q(ltri3),q(ltri2))
_ELSE
            call proc2f(q(ltri1),q(ltri0),q(ltri3),q(ltri2))
_ENDIF
_ENDIF
 60      continue
c  read fa into q(1) to q(l)
c  read 1/2ka into q(2l+1) to q(3l)
 70      call rdedx(q(ltri0),ltri,ibh,ifockf)
         call rdedx(q(ltri2),ltri,ibk,ifockf)
         ij = 0
         do 90 i = 1 , nsa4
            foci = 2.0d0
            if (i.gt.nocca) foci = 1.0d0
            if (i.gt.noccb) foci = 0.0d0
            do 80 j = 1 , i
               focj = 2.0d0
               if (j.gt.nocca) focj = 1.0d0
               if (j.gt.noccb) focj = 0.0d0
               ijt = iky(mapie(i)) + mapie(j) - 1
               ij1 = ijt + ltri0
               ij0 = ij  + ltri1
               ij2 = ijt + ltri2
               ij3 = ij  + ltri2
               q(ij1) = (foci+focj)*(q(ij1)+q(ij0))
     +                  *0.5d0 - (foci*(2.0d0-foci)+focj*(2.0d0-focj))
     +                  *(q(ij3)+q(ij2))*0.5d0
               ij = ij + 1
c
_IF1()c        sign of q(ij2) different cray/ibm  .....
_IF1()c       +q(ij2)   ..... cray
_IF1()c      -q(ij2)   .....ibm
 80         continue
 90      continue
         call wrt3(q(ltri0),ltri,ibt,ifockf)
         ibh = ibh + length
         ibd = ibd + length
         ibk = ibk + length
         ibdo = ibdo + length
         ibt = ibt + length
         if (odebug(4)) write (iwr,6010) n
         if (odebug(4)) call prtris(q(ltri0),ncoorb,iwr)
 100  continue
      call gmem_free(ltri3)
      call gmem_free(ltri2)
      call gmem_free(ltri1)
      call gmem_free(ltri0)
      iochf(1) = ibt
      call revise
      call clredx
      return
 6010 format (//5x,'perturbed fock matrix in m.o. basis -- perturbation'
     +        ,i6/)
      end
      subroutine get1a(a,ifi,ila,mn,n0,ifil)
      implicit REAL  (a-h,o-z)
c
c     used in chfeqv
c
      common/blkin/g(510),nword
INCLUDE(common/atmblk)
_IFN1(iv)      common/craypk/labs(680),lab1(340),lab2(340)
_IF1(iv)      common/craypk/lab1(340),lab2(340)
      dimension a(ila-ifi+1,mn)
c
      ifi1 = ifi - 1
 20   if (n0.eq.1) then
         call get(g,nw)
c
         if (nw.eq.0) then
c...         EOF disable => next reads (see below)
            n0 = -1
            nword = 0
         end if 
c
         if (nword.eq.0) go to 60
_IF(ibm,vax)
         call upak4v(g(num2ep+1),lab1)
_ELSE
         call unpack(g(num2ep+1),lab1632,labs,numlabp)
         n2 = 1
         do n = 1 , nword
            lab1(n) = labs(n2)
            lab2(n) = labs(n2+1)
            n2 = n2 + 2
         enddo
_ENDIF
      end if
      if (n0.lt.0) go to 60
      nnext = n0
      if (lab1(nword).le.ila) then
         do 40 n = nnext , nword
            a(lab1(n)-ifi1,lab2(n)) = g(n)
 40      continue
      else
         do 50 n = nnext , nword
            n0 = n
            if (lab1(n).gt.ila) go to 60
            a(lab1(n)-ifi1,lab2(n)) = g(n)
 50      continue
      end if
      call find(ifil)
      n0 = 1
      go to 20
 60   do 80 i = ifi + 1 , ila
         do 70 j = ifi , i - 1
            a(j-ifi1,i) = a(i-ifi1,j)
 70      continue
 80   continue
      return
      end
      subroutine get2a(a,ifi,ila,mn,ifil)
      implicit REAL  (a-h,o-z)
c
c     used in chfeqv
c
      common/blkin/g(510),nword
INCLUDE(common/atmblk)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/labij(340),labkl(340)
      dimension a(mn,ila-ifi+1)
c
      iblk1 = 1
      call search(iblk1,ifil)
      call find(ifil)
 20   call get(g,nw)
      if (nw.eq.0 .or. nword.eq.0) return
_IFN1(iv)      call unpack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)      call upak4v(g(num2ep+1),labij)
      do 30 n = 1 , nword
_IFN1(iv)         lab1 = labs(n+n-1)
_IFN1(iv)         lab2 = labs(n+n)
_IF1(iv)         lab1 = labij(n)
_IF1(iv)         lab2 = labkl(n)
         if (lab2.ge.ifi .and. lab2.le.ila) a(lab1,lab2-ifi+1) = g(n)
 30   continue
      call find(ifil)
      go to 20
      end
      subroutine lgrhf(a,ibzeta,alphax,betax,fx)
c
c     generalised lagrangian for grhf
c
      implicit REAL  (a-h,o-z)
      dimension a(*),alphax(11,11),betax(11,11),fx(11)
INCLUDE(common/sizes)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/atmblk)
INCLUDE(common/ghfblk)
INCLUDE(common/mapper)
INCLUDE(common/infoa)
INCLUDE(common/prnprn)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/maxlen/maxq
      common/blkin/g(510),nword
      common/mpshl/ns(maxorb)
      logical exist
c     data m21/21/
c
      call bfnshl(ns,nsa4)
c
c     read m.o. t+v matrix off dumpfile
c
      call secloc(isect(21),exist,isec21)
      if (exist) then
         call rdedx(a(1),lds(isect(21)),isec21,ifild)
      else
         call caserr('transformed t+v matrix required')
      end if
c
c     multiply by 1-electron occupation numbers
c
      call actmot(a,nsa4,mapie,iky)
      ij = 0
      do 40 i = 1 , nsa4
         do 30 j = 1 , i
            ij = ij + 1
            fij = 0.5d0*a(ij)
            nn = ij
            do 20 n = 1 , njk1
               a(nn) = fij*fx(n)
               nn = nn + nx
 20         continue
 30      continue
 40   continue
c
c     clear label buffer, labs (i205)
_IFN1(iv)      call setsto(1360,0,labs)
_IF1(iv)      call setsto(1360,0,i205)
c
c     loop over the transformed two-electron integrals
c     which are input from ed6 ( default)
c
      do 230 ifile = 1 , mmfile
         mblkk = kblk(ifile)
         idevm = nufile(ifile)
c        lblkm = nblk(ifile)
c
         call search(mblkk,idevm)
         call find(idevm)
c
c     read block of integrals into /blkin/
c
 50      call get(g(1),nw)
         if (nword.gt.0) then
            if (nw.gt.0) then
               call find(idevm)
c
c     loop over integrals in a block
c
_IFN1(iv)               call unpack(g(num2e+1),lab816,labs,numlab)
_IF1(iv)               call upak8v(g(num2e+1),i205)
               do 220 int = 1 , nword
c
c     unpack the labels
c
_IFN1(iv)                  kk2 = (int+int) + (int+int)
_IF(ibm,vax)
                  i = i205(int)
                  j = j205(int)
                  k = k205(int)
                  l = l205(int)
_ELSEIF(littleendian)
                  i = labs(kk2-2)
                  j = labs(kk2-3)
                  k = labs(kk2  )
                  l = labs(kk2-1)
_ELSE
                  i = labs(kk2-3)
                  j = labs(kk2-2)
                  k = labs(kk2-1)
                  l = labs(kk2)
_ENDIF
                  gg = g(int)
                  it = ijkltp(i,j,k,l)
                  go to (60,60,60,80,120,160,140,180,200,100,100,220,
     +                   220,220) , it
c     <ii/ii>,<ii/il>,<il/ll>
 60               il = iky(i) + l
                  do 70 n = 1 , njk1
                     a(il) = a(il) + gg*(alphax(n,ns(j))+betax(n,ns(j)))
                     il = il + nx
 70               continue
                  go to 220
c     <ii/kk>
 80               kk = iky(k) + k
                  do 90 n = 1 , njk1
                     a(kk) = a(kk) + gg*alphax(n,ns(i))
                     kk = kk + nx
 90               continue
c     <ij/kk>
 100              ij = iky(i) + j
                  do 110 n = 1 , njk1
                     a(ij) = a(ij) + gg*alphax(n,ns(k))
                     ij = ij + nx
 110              continue
                  go to 220
c      <ij/ij>
 120              ii = iky(i) + i
                  do 130 n = 1 , njk1
                     a(ii) = a(ii) + gg*betax(n,ns(j))
                     ii = ii + nx
 130              continue
c     <ij/il>
 140              jl = iky(j) + l
                  do 150 n = 1 , njk1
                     a(jl) = a(jl) + gg*betax(n,ns(i))
                     jl = jl + nx
 150              continue
                  go to 220
c    <ii/kl>
 160              kl = iky(k) + l
                  do 170 n = 1 , njk1
                     a(kl) = a(kl) + gg*alphax(n,ns(i))
                     kl = kl + nx
 170              continue
                  go to 220
c     <ij/jl>
 180              il = iky(i) + l
                  do 190 n = 1 , njk1
                     a(il) = a(il) + gg*betax(n,ns(j))
                     il = il + nx
 190              continue
                  go to 220
c     <ij/kj>
 200              ik = iky(i) + k
                  do 210 n = 1 , njk1
                     a(ik) = a(ik) + gg*betax(n,ns(j))
                     ik = ik + nx
 210              continue
 220           continue
               go to 50
            end if
         end if
 230  continue
      ij = 1
      do 240 n = 1 , njk1
         if (odebug(16)) call prtris(a(ij),nsa4,iwr)
         ij = ij + nx
 240  continue
      call wrt3(a,nx*njk1,ibzeta,ifils)
      return
      end
      subroutine lgrhfm(a,ibeta,alphax,betax,fx)
c
c      lagrangian in mo basis --- from integral list
c      for grhf
c
      implicit REAL  (a-h,o-z)
      dimension a(*),alphax(11,11),betax(11,11),fx(11)
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/atmblk)
INCLUDE(common/ghfblk)
INCLUDE(common/mapper)
INCLUDE(common/prnprn)
      common/maxlen/maxq
      common/mpshl/ns(maxorb)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/blkin/g(510),nword
      logical exist
c     data m21/21/
c
      call bfnshl(ns,nsa4)
c
c     read m.o. t+v matrix off dumpfile
c
      call secloc(isect(21),exist,isec21)
      if (exist) then
        call rdedx(a(1),lds(isect(21)),isec21,ifild)
      else
        call caserr('transformed t+v matrix required')
      end if
c
c     multiply by 1-electron occupation numbers
c
      call actmot(a,nsa4,mapie,iky)
      ij = 0
      do 30 i = 1 , nsa4
         fi = 0.5d0*fx(ns(i))
         do 20 j = 1 , i
            ij = ij + 1
            a(ij) = a(ij)*fi
 20      continue
 30   continue
c
c     clear label buffer, labs (i205)
_IFN1(iv)      call setsto(1360,0,labs)
_IF1(iv)      call setsto(1360,0,i205)
c
c     loop over the transformed two-electron integrals
c     which are input from ed6 ( default)
c
      do 140 ifile = 1 , mmfile
         mblkk = kblk(ifile)
         idevm = nufile(ifile)
c
         call search(mblkk,idevm)
         call find(idevm)
c
c     read block of integrals into /blkin/
c
 40      call get(g(1),nw)
         if (nword.gt.0) then
            if (nw.gt.0) then
               call find(idevm)
c
c     loop over integrals in a block
c
_IFN1(iv)               call unpack(g(num2e+1),lab816,labs,numlab)
_IF1(iv)               call upak8v(g(num2e+1),i205)
               do 130 int = 1 , nword
c
c     unpack the labels
c
_IFN1(iv)                  kk2 = (int+int) + (int+int)
_IF(ibm,vax)
                  i = i205(int)
                  j = j205(int)
                  k = k205(int)
                  l = l205(int)
_ELSEIF(littleendian)
                  i = labs(kk2-2)
                  j = labs(kk2-3)
                  k = labs(kk2  )
                  l = labs(kk2-1)
_ELSE
                  i = labs(kk2-3)
                  j = labs(kk2-2)
                  k = labs(kk2-1)
                  l = labs(kk2)
_ENDIF
                  gg = g(int)
                  it = ijkltp(i,j,k,l)
                  go to (50,50,50,60,80,100,90,110,120,70,70,130,130,
     +                   130) , it
 50               il = iky(i) + l
                  a(il) = a(il)
     +                    + gg*(alphax(ns(i),ns(j))+betax(ns(i),ns(j)))
                  go to 130
 60               kk = iky(k) + k
                  a(kk) = a(kk) + gg*alphax(ns(k),ns(i))
 70               ij = iky(i) + j
                  a(ij) = a(ij) + gg*alphax(ns(i),ns(k))
                  go to 130
 80               ii = iky(i) + i
                  a(ii) = a(ii) + gg*betax(ns(i),ns(j))
 90               jl = iky(j) + l
                  a(jl) = a(jl) + gg*betax(ns(j),ns(i))
                  go to 130
 100              kl = iky(k) + l
                  a(kl) = a(kl) + gg*alphax(ns(k),ns(i))
                  go to 130
 110              il = iky(i) + l
                  a(il) = a(il) + gg*betax(ns(i),ns(j))
                  go to 130
 120              ik = iky(i) + k
                  a(ik) = a(ik) + gg*betax(ns(i),ns(j))
 130           continue
               go to 40
            end if
         end if
 140  continue
      if (odebug(16)) call prtris(a,nsa4,iwr)
      call wrt3(a,nx,ibeta,ifils)
      return
      end
      subroutine umat(f,s,e,u,ltri,norb,nat3)
c
c     produces full u matrix (including  redundant terms)
c     for nuclear perturbations
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension f(ltri),s(ltri),e(norb),u(norb,norb,nat3)
INCLUDE(common/infoa)
INCLUDE(common/mapper)
c
INCLUDE(common/common)
INCLUDE(common/cndx41)
c
      ind(i,j) = iky(max(i,j)) + min(i,j)
c
      ifile1 = 1
c
c
      call secget(isect(9),9,isec9)
      call rdedx(e,ncoorb,isec9,ifild)
c     perturbed fock matrix at section 16 , m.o. basis
c     derivatives of overlap at section 14
c
      ibf = iochf(16)
      ibs = iochf(14)
      length = lensec(ltri)
      call vclr(u(1,1,nat3-2),1,3*norb*norb)
      do 40 n = 1 , nat3 - 3
         call rdedx(f,ltri,ibf,ifockf)
         call rdedx(s,ltri,ibs,ifockf)
         ibf = ibf + length
         ibs = ibs + length
         do 30 i = 1 , ncoorb
            do 20 j = 1 , ncoorb
               diff = e(j) - e(i)
c
               if (dabs(diff).gt.1.0d-3) then
                  u(i,j,n) = (f(ind(i,j))-s(ind(i,j))*e(j))/diff
               else
                  u(i,j,n) = -s(ind(i,j))*0.5d0
               end if
c
               if (dabs(u(i,j,n)).le.1.0d-15) u(i,j,n) = 0.0d0
c
 20         continue
 30      continue
 40   continue
c
      call wrt3(u,norb*norb*nat3,mpblk(6),ifile1)
c
      ibf = iochf(16)
      do 70 n = 1 , nat3 - 3
         call rdedx(f,ltri,ibf,ifockf)
         ibf = ibf + length
c
         ipiq = 0
         do 60 ipp = 1 , norb
            do 50 iq = 1 , ipp
               ipiq = ipiq + 1
               diff = e(ipp) - e(iq)
               if (dabs(diff).gt.1.0d-3) then
                  u(ipp,iq,n) = 0.0d0
               else
                  u(ipp,iq,n) = f(ipiq) + u(ipp,iq,n)*e(ipp)
     +                          + u(iq,ipp,n)*e(iq)
               end if
               u(iq,ipp,n) = u(ipp,iq,n)
 50         continue
 60      continue
 70   continue
      call wrt3(e,norb,mpblk(4),ifile1)
      call wrt3(u,norb*norb*nat3,mpblk(5),ifile1)
      return
      end
      subroutine umatef(f,e,eder,u,ltri,norb,npert)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension f(ltri),e(norb),eder(norb,norb,npert),
     1   u(norb,norb,npert)
c
c     makes all the u-vector elements, including redundant pairs
c     for electric field perturbations, and perturbed fock
c     operator elements
c
INCLUDE(common/mapper)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
      character*10 charwall
c
      ind(i,j) = iky(max(i,j)) + min(i,j)
c
c
      call secget(isect(9),9,isec9)
      call rdedx(e,lds(isect(9)),isec9,ifild)
c
c      perturbed fock matrices from section 70 thru 72 of dumpfile
c
      ifout = 70
      do 80 n = 1 , npert
         if (ione(n+3).ne.0) then
            call secget(isect(ifout),ifout,ibf)
            call rdedx(f,ltri,ibf,ifild)
c
c     perturbed eigenvalues
c
            call vclr(eder(1,1,n),1,ncoorb*ncoorb)
            do 30 i = 1 , nocca
               do 20 j = 1 , i
                  ij = iky(i) + j
                  eder(i,j,n) = f(ij)
                  eder(j,i,n) = eder(i,j,n)
 20            continue
 30         continue
            do 50 i = nocca + 1 , ncoorb
               do 40 j = nocca + 1 , i
                  ij = iky(i) + j
                  eder(i,j,n) = f(ij)
                  eder(j,i,n) = eder(i,j,n)
 40            continue
 50         continue
            call vclr(u(1,1,n),1,ncoorb*ncoorb)
            do 70 ia = nocca + 1 , ncoorb
               do 60 i = 1 , nocca
                  diff = e(ia) - e(i)
                  u(ia,i,n) = -f(ind(ia,i))/diff
                  u(i,ia,n) = -u(ia,i,n)
 60            continue
 70         continue
         end if
         ifout = ifout + 1
 80   continue
      ifile1 = 1
      call wrt3(e,ncoorb,mpblk(4),ifile1)
      call wrt3(eder,ncoorb*ncoorb*npert,mpblk(5),ifile1)
      call wrt3(u,ncoorb*ncoorb*npert,mpblk(6),ifile1)
      write (iwr,6010) cpulft(1) ,charwall()
 6010 format(/1x,'derivative eigenvalue generation complete at ',
     +  f8.2,' seconds',a10,' wall')
      return
      end
      subroutine nrmap(mnr,nocca,noccb,nsa,iky,mapie)
      implicit REAL  (a-h,o-z)
      dimension mnr(*),mapie(*),iky(*)
c
c     nsa is total number of active m.o.'s
c     nocca is number of doubly occupied
c     noccb is total occupied
c
c     maps from lower triangle to
c     non-redundant pairs
c
      nsoc = noccb - nocca
      nvirta = nsa - noccb
      ntpls1 = noccb + 1
      ndpls1 = nocca + 1
      if (nocca.ne.0) then
         do 30 j = 1 , nocca
            do 20 i = ndpls1 , nsa
               it = (i-ndpls1)*nocca + j
               mnr(it) = iky(mapie(i)) + mapie(j)
 20         continue
 30      continue
      end if
      if (noccb.ne.nocca) then
         do 50 j = ndpls1 , noccb
            do 40 i = ntpls1 , nsa
               it = nvirta*nocca + (i-nsoc-1)*nsoc + j - nocca
               mnr(it) = iky(mapie(i)) + mapie(j)
 40         continue
 50      continue
      end if
      return
      end
      subroutine mxmau1(a,u,au,mn,ifi,ila,irange,np,irmax)
      implicit REAL  (a-h,o-z)
c
c     used in chfeqv
c
      dimension a(irange,mn),u(mn,np),au(mn,np)
      ir = irange
      jr = ila
      if (ir.le.0 .or. jr.le.0 .or. np.le.0) return
      call mxmb(a,1,irange,u,1,mn,au(ifi,1),1,mn,ir,jr,np)
      jr = ir
      ir = ifi - 1
      if (ir.gt.0) call mxmb(a,irange,1,u(ifi,1),1,mn,au,1,mn,ir,jr,np)
      ifi = ila + 1
      ila = ila + irmax
      if (ila.gt.mn) ila = mn
      return
      end
      subroutine mxmau2(a,u,au,mn,ifi,ila,ir,np,irmax)
      implicit REAL  (a-h,o-z)
c
c     used in chfeqv
c
      dimension a(mn,ir),u(mn,np),au(mn,np)
      if (ir.le.0 .or. np.le.0) return
      call mxmb(a,1,mn,u(ifi,1),1,mn,au,1,mn,mn,ir,np)
      ifi = ila + 1
      ila = ila + irmax
      if (ila.gt.mn) ila = mn
      return
      end
      subroutine symfck(qq,iso,nshels)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension qq(*),iso(nshels,*)
INCLUDE(common/mapper)
      common/mpshl/ns(maxorb)
INCLUDE(common/nshel)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
INCLUDE(common/symtry)
      common/bufb/ptr(3,144),ict(maxat,8)
      common/symmos/imos(8,maxorb)
      data one/1.0d0/
c
      ind(i,j) = iky(max(i,j)) + min(i,j)
c
c     write(iwr,*) 'entered mpfsym..number of operations ',nt
      if (nt.eq.1) return
c
      nav = lenwrd()
c
      call rdedx(ptr(1,1),nw196(1),ibl196(1),ifild)
      call readi(iso,nw196(5)*nav,ibl196(5),ifild)
      do 40 ii = 1 , nshell
         ic = katom(ii)
         do 30 it = 1 , nt
            id = iso(ii,it)
            ict(ic,it) = katom(id)
 30      continue
 40   continue
c
      ntri = ncoorb*(ncoorb+1)/2
c     n2 = ncoorb*ncoorb
      iblen = lensec(ntri)
      iblok = iochf(16)
      an = one/dfloat(nt)
      ioff = ntri + 1
      nat3 = nat*3
c     n3n = nat3
c     read in m.o. perturbed fock matrix
      do 50 n = 1 , nat3
         call rdedx(qq(ioff),ntri,iblok,ifockf)
         iblok = iblok + iblen
         ioff = ioff + ntri
 50   continue
c     loop over matrices
      iblok = iochf(16)
      do 130 n = 1 , nat
         do 120 nc = 1 , 3
            ioff = ((n-1)*3+nc)*ntri
c     copy matrix for atom n component nc into work area
c     this is equivalent to identity
            do 60 i = 1 , ntri
               qq(i) = qq(ioff+i)
 60         continue
c     work along the elements of this matrix
            do 100 iip = 1 , ncoorb
               do 90 iiq = 1 , iip
                  ipq = ind(iip,iiq)
c     loop over symmetry operations
c     except identity
                  do 80 iop = 2 , nt
                     isign = imos(iop,iip)*imos(iop,iiq)
                     sign = dfloat(isign)
                     niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                     ioff = (niop-1)*3*ntri
                     npnc = (iop-1)*3 + nc
                     do 70 k = 1 , 3
                        ioff = ioff + ntri
                        qq(ipq) = ptr(k,npnc)*sign*qq(ioff+ipq)
     +                            + qq(ipq)
 70                  continue
 80               continue
 90            continue
 100        continue
            do 110 i = 1 , ntri
               qq(i) = an*qq(i)
 110        continue
            call wrt3(qq(1),ntri,iblok,ifockf)
            iblok = iblok + iblen
 120     continue
 130  continue
      return
      end
      subroutine wamat(a,mnmn,ifil,nst,nfin,odebug,iww)
c
c     writes out a-matrix ( hessian ) as constructed by chfcls
c     ( and equivalent open-shell routines)
c     -------------------------------------------------------
      implicit REAL  (a-h,o-z)
      dimension a(*)
      logical odebug
INCLUDE(common/cigrad)
INCLUDE(common/common)
INCLUDE(common/atmblk)
c
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/labij(340),labkl(340)
      common/blkin/g(510),nint
      data m0/0/
c
_IFN1(iv)      call setsto(680,0,labs)
_IF1(iv)      call setsto(680,0,labij)
c
      nint = m0
      nstp1 = nst + 1
      itri = m0
      do 30 i = nstp1 , nfin
         do 20 j = 1 , i
            itri = itri + 1
            val = a(itri)
            if (val.ne.0.0d0) then
               nint = nint + 1
               g(nint) = val
_IFN1(iv)               labs(nint+nint-1) = i
_IFN1(iv)               labs(nint+nint) = j
_IF1(iv)               labij(nint) = i
_IF1(iv)               labkl(nint) = j
               if (nint.ge.num2e) then
_IFN1(iv)                  call pack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)                  call pak4v(labij,g(num2ep+1))
                  call put(g,m511,ifil)
_IFN1(iv)                  call setsto(680,0,labs)
_IF1(iv)                  call setsto(680,0,labij)
                  nint = m0
               end if
               if (.not.(.not.lcpf .and. .not.cicv .and. (.not.cicx)))
     +             then
                  if (i.ne.j) then
                     nint = nint + 1
                     g(nint) = val
_IFN1(iv)                     labs(nint+nint-1) = j
_IFN1(iv)                     labs(nint+nint) = i
_IF1(iv)                     labij(nint) = j
_IF1(iv)                     labkl(nint) = i
                     if (nint.ge.num2e) then
_IFN1(iv)                        call pack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)                        call pak4v(labij,g(num2ep+1))
                        call put(g,m511,ifil)
_IFN1(iv)                        call setsto(680,0,labs)
_IF1(iv)                        call setsto(680,0,labij)
                        nint = m0
                     end if
                  end if
               end if
            end if
 20      continue
 30   continue
      if (nint.ne.m0) then
_IFN1(iv)         call pack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)         call pak4v(labij,g(num2ep+1))
         call put(g,m511,ifil)
_IFN1(iv)         call setsto(680,0,labs)
_IF1(iv)         call setsto(680,0,labij)
         nint = m0
      end if
      if (.not.(lcpf .or. cicv .or. cicx)) then
         if (nfin.eq.mnmn) call put(g,m0,ifil)
      end if
      if (odebug) write (iww,6010)
      if (odebug) call prtris(a,mnmn,iww)
      return
 6010 format (///1x,'a-matrix')
      end
      subroutine polasm(b,u,prop,ndim,npdim)
c
c    assemble and print out polarisabilities
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
INCLUDE(common/prnprn)
      dimension prop(npdim,npdim),orb(100,6)
      dimension b(ndim,np),u(ndim,np)
      character *8 closed
      data closed /'closed'/
c
c
      call vclr(prop,1,npdim*npdim)
c
c     read in pertubation vectors in b
c
      call rdedv(b,ndim,np,iblks,ifils)
c
c     read the solution vectors in u
c
      call rdedvs(u,ndim,np,ifils)
c
      do 30 i = 1 , np
         do 20 j = 1 , np
            zz = -4.0d0*ddot(mn,u(1,i),1,b(1,j),1)
            prop(i,j) = zz
 20      continue
 30   continue
c
c
      if(oprn(40)) call prpol0(prop,npdim)
      if (scftyp.ne.closed) return
      if (nocca.gt.100) return
      call vclr(orb,1,600)
      nnn = 0
      do 70 k = 1 , 3
         do 60 l = 1 , k
            nnn = nnn + 1
            mmm = 0
            do 50 j = nocca + 1 , nsa4
               do 40 i = 1 , nocca
                  mmm = mmm + 1
                  orb(i,nnn) = orb(i,nnn) - 4.0d0*u(mmm,k)*b(mmm,l)
 40            continue
 50         continue
 60      continue
 70   continue
      if(oprn(26) .and. oprn(40)) then
       write (iwr,6010)
       do 80 i = 1 , nocca
          write (iwr,6020) i , (orb(i,j),j=1,6)
 80    continue
      endif
      return
 6010 format (/
     + 10x,'***********************************************'/
     + 10x,'* m.o. contributions to dipole polarizability *'/
     + 10x,'***********************************************'//
     + 1x,'m.o.',8x,'xx',16x,'xy',16x,'yy',16x,'xz',16x,'yz',16x,
     +        'zz'/)
 6020 format (1x,i4,6f18.8)
      end
      subroutine poldrv(q,iq)
c
c      driving routine for polarisability calculations
c      -----------------------------------------------
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical lmag,ldynam,lbig,lstop,skipp
      dimension skipp(100)
c
INCLUDE(common/ghfblk)
INCLUDE(common/infoa)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
INCLUDE(common/mapper)
      common /maxlen/ maxq
      common/mpshl/ns(maxorb)
      logical lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis
      common/scfblk/en,etot,ehf,sh1(2),sh2(2),gap1(2),gap2(2),
     1              d12,d13,d23,canna,cannb,cannc,fx,fy,fz,
     2              lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis,
     3              ncyc,ischm,lock,maxit,nconv,npunch,lokcyc
      common /small / abcis(30),weight(30)
INCLUDE(common/statis)
INCLUDE(common/drive_dft)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
      logical ogeompert_save
      dimension iq(*)
      dimension q(*)
      character *8 closed,oscf,grhf,open
      data closed,oscf,grhf,open/'closed','oscf','grhf','open'/
c
_IF(ccpdft)
      ierror = CD_set_2e()
_ENDIF
      lenx = lensec(nx)*nat*15
      call cpuwal(begin,ebegin)
      call wrt3z(iblks,ifils,lenx)
      if (scftyp.eq.oscf) then
         if((dabs(canna-2.0d0).gt.1.0d-6).or.
     +      (dabs(cannb).gt.1.0d-6).or.
     +      (dabs(cannc+2.0d0).gt.1.0d-6)) then
            write (iwr,6010)
            call caserr('stop')
         end if
      end if
c...  structure of section
c     a) /tdhf/ 1 block
      lds(isect(52)) = 31 + lenint(192)
      ldsect(isect(52)) = 50
c     b) trans energies at least 1 block
c     c) trans moments at least 1 block
c     d) properties nfreq+1 blocks
c
c   ======= next bit mainly for setting up dynamic props.
c...  restore if necessary
      ifreq = 0
      if (irestp.ne.0) then
         call secget(isect(52),52,iblkj)
         call rdchr(pnames,ldsect(isect(52)),iblkj,ifild)
         call reads(freq,lds(isect(52)),ifild)
         write (iwr,6020) isect(52) , irestp , ifreq
      end if
c
      lbig = npole.lt.0 .or. npole.eq.999
      if (irestp.eq.4) then
         ieps = igmem_alloc(mn)
         call tdchf(q(ieps),lbig)
         call gmem_free(ieps)
      else
         if (npole.eq.999) npole = 0
         npole = iabs(npole)
         ldynam = nfreq.ne.0 .or. npole.ne.0
         lmag = ldynam
         npdim = max(np,9)
         len = 2 + lensec(npole) + lensec(npole*np) + (iabs(nfreq)+1)
     +         *lensec(npdim*npdim)
         call secput(isect(52),52,len,iblkj)
         call revind
         call wrtc(pnames,ldsect(isect(52)),iblkj,ifild)
         call wrt3s(freq,lds(isect(52)),ifild)
c
c
c  ======================================
         imap  = igmem_alloc(lenint(nx))
         iimap = lenrel(imap-1)+1
         if (scftyp.eq.open) then
            write(*,*)'UHF polarizabilities are not supported'
            call caserr('No UHF polarizabilities')
         endif
         if (scftyp.ne.grhf) then
            if (noccb.lt.nocca) then
c              Original CADPAC code assumes noccb >= nocca
               call caserr('Code broken try GRHF instead')
            endif
            mn = noccb*nvirta + (noccb-nocca)*nocca
            call grhfbl(scftyp)
            call bfnshl(ns,nsa4)
            call nrmapo(iq(iimap),nocca,noccb,nsa4,iky,mapie)
         else
            call bfnshl(ns,nsa4)
            call ijmapr(nsa4,ns,iq(iimap),mn,mnx)
         end if
         ieps = igmem_alloc(mn)
c
c     sort out required integrals ( form a-matrix )
c
         i01 = igmem_alloc_all(maxa)
         if (scftyp.eq.closed) call chfcls(q(i01),maxa)
         if (scftyp.eq.oscf) call chfops(q(i01),maxa)
         call gmem_free(i01)
         if (scftyp.eq.grhf) then
            lenblk = lensec(mn)
            ibeta = iblks + lenblk*nat*6
            ibzeta = ibeta + lensec(nx)
c           i2 = i1 + nx*njk1
            i01 = igmem_alloc(nx)
            i1  = igmem_alloc(nx*njk1)
            i2  = igmem_alloc_all(maxa)
            call lgrhfm(q(i01),ibeta,erga,ergb,fjk)
            call lgrhf(q(i1),ibzeta,erga,ergb,fjk)
            call chfgrs(q(ieps),iq(iimap),q(i01),q(i1),q(i2),
     +                  ibeta,ibzeta,maxa)
            call gmem_free(i2)
            call gmem_free(i1)
            call gmem_free(i01)
         end if
         i01 = igmem_alloc_all(maxa)
         if (lmag) call chficl(q(i01),maxa)
         call gmem_free(i01)
c
c
c   right-hand-side of equations
c
         i01 = igmem_alloc(mn)
         i1  = igmem_alloc(nx)
         call rhsemp(q(ieps),q(i01),q(i1),iq(iimap))
         call gmem_free(i1)
         call gmem_free(i01)
c    solve chf equations
c
         lstop = .false.
         do 30 n = 1 , np
            skipp(n) = .false.
 30      continue
         ogeompert_save = ogeompert
         ogeompert = .false.
         call chfdrv(q(ieps),lstop,skipp)
         ogeompert = ogeompert_save
         if (lstop) then
            write (iwr,*)
     +         'insufficient time - restart polarizability from'
     +         , ' beginning'
            call timana(22)
            call clenms('stop')
         end if
         if (ifreq.gt.0) then
            call tdchf(q(ieps),lbig)
         else
c
c     construct perturbed density matrices
c
            if (ldens .or. ldiag) then
               i01 = igmem_alloc(mn)
               i1  = igmem_alloc(nx)
               call efdens(q(i01),q(i1))
               call gmem_free(i1)
               call gmem_free(i01)
            endif
c
c     assemble polarizability tensors
c
            npdim = max(np,9)
            i1 = i01 + mn*np
            i2 = i1 + mn*np
c           i3 = i2 + npdim*npdim
            i01 = igmem_alloc(mn*np)
            i1  = igmem_alloc(mn*np)
            i2  = igmem_alloc(npdim*npdim)
            call polasm(q(i01),q(i1),q(i2),mn,npdim)
            leng = lensec(mn)*np
            call secput(isect(65),65,leng,iblok)
            lds(isect(65)) = mn*np
            call search(iblok,ifild)
            do 40 i = 1 , np
               call wrt3s(q(i1+(i-1)*mn),mn,ifild)
 40         continue
            call revind
            call gmem_free(i2)
            call gmem_free(i1)
            call gmem_free(i01)
c
c     construct complete perturbed fock matrix if requested
c
            if (ldiag) then
               i01 = igmem_alloc_all(maxa)
               call effock(q(i01))
               call gmem_free(i01)
            endif
c           call timit(1)
            if (npole.ne.0 .or. nfreq.ne.0) then
               if (scftyp.ne.closed) then
                  write (iwr,6030)
               else
                  call tdchf(q(ieps),lbig)
               end if
            end if
         end if
         call gmem_free(ieps)
         call gmem_free(imap)
      end if
      irestp = 0
      nfreq = 0
      npole = 0
_IF(ccpdft)
      ierror = CD_reset_2e()
_ENDIF
      call revise
      call secget(isect(52),52,iblkj)
      call wrtc(pnames,ldsect(isect(52)),iblkj,ifild)
      call wrt3s(freq,lds(isect(52)),ifild)
      call delfil(nofile(1))
      call timana(22)
      return
 6010 format (/1x,'oscf chf equations only work with',
     +        ' canonicalisation 2.0, 0.0, -2.0'/1x,
     +        '------     see manual for details --------')
 6020 format (' restart information restored from section',i4,
     +        ' of dumpfile'/' irestp =',i3/' ifreq =',i3/)
 6030 format (//1x,'dynamic properties only available for',
     +        ' closed-shell systems')
      end
      subroutine prpol1(prop,npdim,mini,maxi,nstart,fac,iw)
      implicit REAL  (a-h,o-z)
c
c     another printing routine for polarisabilities
c
      character *8 pbuff
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
      dimension prop(npdim,npdim)
      dimension pbuff(6),pout(6)
      nnn = 0
      do 20 i = mini , maxi
         if (.not.(opskip(i))) then
            nnn = nnn + 1
            pbuff(nnn) = pnames(i)
         end if
 20   continue
      if (nnn.eq.0) return
      write (iw,6010) (pbuff(i),i=1,nnn)
      nj = 0
      do 40 j = 1 , 50
         if (.not.(opskip(j))) then
            nj = nj + 1
            nnn = 0
            do 30 i = mini , maxi
               if (.not.(opskip(i))) then
                  nnn = nnn + 1
                  pout(nnn) = prop(nnn+nstart,nj)/fac
               end if
 30         continue
            write (iw,6020) pnames(j) , (pout(i),i=1,nnn)
         end if
 40   continue
      nstart = nstart + nnn
      return
 6010 format (//3x,'perturbed',25x,'perturbation'/3x,'operator',4x,
     +        6(4x,a8,5x))
 6020 format (/2x,a8,2x,6f17.8)
      end
      subroutine prpol0(prop,npdim)
c
      implicit REAL  (a-h,o-z)
c
c     printing routine for polarisabilities
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
      character *1 tag
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
c
INCLUDE(common/prnprn)
c
      dimension prop(npdim,npdim)
      dimension alpha(6,6),tag(3)
c
      data zero,three,con1/0.0d0,3.0d0,0.16487762d0/
      data tag/'x','y','z'/
c
      call secget(isect(52),52,iblkj)
      iblkj = iblkj + 2 + lensec(npole) + lensec(npole*np)
     +        + ifreq*lensec(npdim*npdim)
      call wrt3(prop,npdim*npdim,iblkj,ifild)
      if (ifreq.ne.0 .and. freq(ifreq).ne.0.0d0) then
         write (iwr,6010) freq(ifreq)
         call prfreq(2,freq(ifreq))
         if (opunch(5)) write (ipu,6020) freq(ifreq)
      else
         if (oprn(26) .and. oprn(40)) write (iwr,6030)
         if (opunch(5)) write (ipu,6040)
      end if
      if (opunch(5)) write (ipu,6050) ((prop(i,j),i=1,np),j=1,np)
      if (ogen) then
         nstart = 0
         fac = 1.0d0
         mini = 1
         maxi = 6
 20      call prpol1(prop,npdim,mini,maxi,nstart,fac,iwr)
         mini = mini + 6
         if (mini.gt.np) return
         maxi = maxi + 6
         if (maxi.gt.np) maxi = np
         go to 20
      else
c
c     construct dipole-polarizability
c
         do 40 i = 1 , 3
            do 30 j = 1 , 3
               alpha(i,j) = zero
 30         continue
 40      continue
         npd = 0
         np1 = 0
         do 60 i = 1 , 3
            if (.not.(opskip(i))) then
               np1 = np1 + 1
               npd = npd + 1
               np2 = 0
               do 50 j = 1 , i
                  if (.not.(opskip(j))) then
                     np2 = np2 + 1
                     alpha(i,j) = prop(np1,np2)
                     alpha(j,i) = prop(np2,np1)
                  end if
 50            continue
            end if
 60      continue
         if (np1.ne.0) then
            if (oprn(26) .and. oprn(40)) write (iwr,6070) (tag(i),i=1,3)
            do 70 i = 1 , 3
               if (oprn(26) .and. oprn(40)) 
     +         write (iwr,6060) tag(i) , (alpha(i,j),j=1,3)
 70         continue
c
c     convert polarizability to s.i. units
c
            do 90 i = 1 , 3
               do 80 j = 1 , 3
                  alpha(i,j) = con1*alpha(i,j)
 80            continue
 90         continue
            if (oprn(26) .and. oprn(40)) write (iwr,6080) (tag(i),i=1,3)
            do 100 i = 1 , 3
               if (oprn(26) .and. oprn(40)) 
     +         write (iwr,6060) tag(i) , (alpha(i,j),j=1,3)
 100        continue
         end if
c
c
c    construct the dipole-quadrupole polarizability (a tensor)
c
         do 120 i = 1 , 6
            do 110 j = 1 , 6
               alpha(i,j) = zero
 110        continue
 120     continue
         np1 = 0
         do 140 i = 1 , 3
            if (.not.(opskip(i))) then
               np1 = np1 + 1
               np2 = npd
               do 130 j = 1 , 6
                  if (.not.(opskip(j+3))) then
                     np2 = np2 + 1
                     alpha(i,j) = prop(np1,np2)
                  end if
 130           continue
            end if
 140     continue
         if (np2.eq.npd) return
         if (oprn(26) .and. oprn(40) )
     +       write (iwr,6090)
         do 150 i = 1 , 3
            if (oprn(26) .and. oprn(40) )
     +       write (iwr,6100) (alpha(i,j),j=1,6)
 150     continue
c
c     quadrupole-quadrupole polarizability (c tensor)
c
         do 170 i = 1 , 6
            do 160 j = 1 , 6
               alpha(i,j) = zero
 160        continue
 170     continue
         np1 = npd
         do 190 i = 1 , 6
            if (.not.(opskip(i+3))) then
               np1 = np1 + 1
               np2 = npd
               do 180 j = 1 , 6
                  if (.not.(opskip(j+3))) then
                     np2 = np2 + 1
                     alpha(i,j) = prop(np1,np2)/three
                  end if
 180           continue
            end if
 190     continue
         if (oprn(26) .and. oprn(40) )
     +       write (iwr,6110)
         do 200 i = 1 , 6
            if (oprn(26) .and. oprn(40) )
     +       write (iwr,6100) (alpha(i,j),j=1,6)
 200     continue
         return
      end if
 6010 format (//10x,'****************************************'/10x,
     +        'second order properties at omega squared =',f20.10/10x,
     +        '****************************************'/)
 6020 format (1x,'dynamic polarizabilty at omega squared=',f16.6)
 6030 format (//
     +   30x,'**********************************'/
     +   30x,'* static second order properties *'/
     +   30x,'**********************************'/)
 6040 format (1x,'static polarizability')
 6050 format (1x,3e20.12)
 6060 format (/10x,a1,3f15.7)
 6070 format (//10x,'========================='/
     +          10x,'= polarizability tensor ='/
     +          10x,'========================='//
     +          10x,'in atomic units (bohr**3)'//
     +              18x,a1,14x,a1,14x,a1)
 6080 format (//10x,
     +        'in s.i. units (10**-40 farad meter**2)'//
     +     18x,a1,14x,a1,14x,a1)
 6090 format (//10x,'==============================================='/
     +          10x,'= dipole-quadrupole polarizability (a tensor) ='/
     +          10x,'==============================================='//
     +          10x,'in atomic units (bohr**4)'//)
 6100 format (10x,6f15.7)
 6110 format (//
     +  10x,'==================================================='/
     +  10x,'= quadrupole-quadrupole polarizability (c tensor) ='/
     +  10x,'==================================================='//
     +  10x,'in atomic units (bohr**5)'//)
      end
      subroutine chfopo(a,maxa,mn,ifil,iblk,lblk,ifils,iblks,
     &   nocca,nsoc,nvirta)
      implicit REAL  (a-h,o-z)
c
c     writes out results from sorto
c
      dimension a(mn,*)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/labij(340),labkl(340)
      common/blkin/g(510),nint
      common/maxlen/maxq
INCLUDE(common/atmblk)
      data m0/0/
      npass = ((mn*mn)/maxa) + 1
      ncol = maxa/mn
      if (ncol.gt.mn) ncol = mn
      nst = 1
      nfin = ncol
      call search(iblk,ifil)
      lblk = 0
      do 80 np = 1 , npass
         call vclr(a,1,mn*ncol)
         call search(iblks,ifils)
 20      call find(ifils)
         call get(g,nw)
         if (nw.eq.0) then
            nint = 0
            nsd1 = nocca*nsoc
            nsv = nsd1 + nocca*nvirta
            nsd1 = nsd1 + 1
c           mini = 1
            do 50 j = nst , nfin
               do 40 i = 1 , j
                  val = a(i,j-nst+1)
                  if (val.ne.0.0d0) then
                     if (i.lt.nsd1 .or. i.gt.nsv) val = val*0.5d0
                     nint = nint + 1
                     g(nint) = val
_IF(ibm,vax)
                     labij(nint) = j
                     labkl(nint) = i
                     if (nint.ge.num2e) then
                     call pak4v(labij,g(num2ep+1))
_ELSE
                     labs(nint+nint-1) = j
                     labs(nint+nint) = i
                     if (nint.ge.num2e) then
                     call pack(g(num2ep+1),lab1632,labs,numlabp)
_ENDIF
                     call put(g,m511,ifil)
_IF1(iv)                     call setsto(680,0,labij)
_IFN1(iv)                     do 30 iiii = 1 , 680
_IFN1(iv)                        labs(iiii) = 0
_IFN1(iv) 30                  continue
                     nint = 0
                     lblk = lblk + 1
                     end if
                  end if
 40            continue
 50         continue
            if (nint.ne.0) then
_IFN1(iv)               call pack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)              call pak4v(labij,g(numlabp))
               call put(g,m511,ifil)
_IF1(iv)               call setsto(680,0,labij)
_IFN1(iv)               do 60 iiii = 1 , 680
_IFN1(iv)                  labs(iiii) = 0
_IFN1(iv) 60            continue
               lblk = lblk + 1
               nint = 0
            end if
            nst = nst + ncol
            nfin = nfin + ncol
            if (nfin.gt.mn) nfin = mn
         else
_IFN1(iv)            call unpack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)            call upak4v(g(num2ep+1),labij)
            do 70 n = 1 , nint
_IFN1(iv)               i = labs(n+n-1)
_IFN1(iv)               j = labs(n+n)
_IF1(iv)               i = labij(n)
_IF1(iv)               j = labkl(n)
               if (j.ge.nst .and. j.le.nfin) then
                  a(i,j-nst+1) = a(i,j-nst+1) + g(n)
               end if
 70         continue
            go to 20
         end if
 80   continue
      nint = 0
_IFN1(iv)      call pack(g(num2ep+1),16,labs,numlabp)
_IF1(iv)      call pak4v(labij,g(num2ep+1))
      call put(g,m0,ifil)
      lblk = lblk + 1
      return
      end
_IF(rpagrad)
c
c-----------------------------------------------------------------------
c
      subroutine rhscl_ij(bx,by,bz,eval,sx,sy,sz)
      implicit REAL  (a-h,o-z)
c
c     r h s of chf equations ( nuclear displacements )
c     Calculating the core-core part of the right-hand-side
c
      dimension bx(*),by(*),bz(*),eval(*),sx(*),sy(*),sz(*)
c
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/atmblk)
      common/maxlen/maxq
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
_IFN1(iv)      common/small/labout(1360)
_IF1(iv)      common/small/labij(340),labkl(340)
      common/blkin/gin(510),nword
      common/out/gout(510),nw
      data smal/1.0d-20/
      data zero,one,half,four/0.0d0,1.0d0,0.5d0,4.0d0/
c
c     sorts out scf eigenvalues and perturbation matrix elements
c
_IFN1(iv)      do 20 iiii = 1 , 1360
_IFN1(iv)         labout(iiii) = 0
_IFN1(iv) 20   continue
_IF1(iv)      call izero(680,labij,1)
      nplus1 = nocca + 1
      call secget(isect(9),9,isec9)
c
c     read in eigenvalues
c
      call rdedx(eval,lds(isect(9)),isec9,ifild)
c
c     sort out integrals involving 0 virtual m.o.'s
c
      i = 0
      j = 0
      k = 0
      l = 0
      mnij = nocca*nocca
      ifili = nufile(1)
      ifilo = ifils
      ib1 = kblk(1)
      ib2 = nblk(1)
      nw = 0
      nat3 = nat*3
      iblll = lensec(mnij)
      iblkb = iblks
      ib3 = iblkb + iblll*nat3
      call search(ib1,ifili)
      call wrt3z(iblkb,ifilo,ib3)
      call search(ib3,ifilo)
      do 70 ibl = ib1 , ib2
         call find(ifili)
         call get(gin,nn)
c
c     complete list of two-electron integrals coming
c     in from transformed mainfile.
c     those of form <ij/kl> going out
c     on scratchfile (ed7)
c
         if (nn.eq.0) go to 80
_IFN1(iv)        call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(gin(num2e+1),i205)
         do 60 n = 1 , nword
_IFN1(iv)            n4 = (n+n) + (n+n)

_IF(ibm,vax)
            i = i205(n)
            j = j205(n)
            k = k205(n)
            l = l205(n)
_ELSEIF(littleendian)
            i = labs(n4-2)
            j = labs(n4-3)
            k = labs(n4  )
            l = labs(n4-1)
_ELSE
            i = labs(n4-3)
            j = labs(n4-2)
            k = labs(n4-1)
            l = labs(n4)
_ENDIF
            if (i.le.nocca) then
c              [ij|kl]
               nw = nw + 1
               gout(nw) = gin(n)
_IFN1(iv)               n4 = (nw+nw) + (nw+nw)
_IFN1(iv)               labout(n4-3) = i
_IFN1(iv)               labout(n4-2) = j
_IFN1(iv)               labout(n4-1) = k
_IFN1(iv)               labout(n4) = l
_IF1(iv)               labij(nw) = j + i4096(i)
_IF1(iv)               labkl(nw) = l + i4096(k)
               if (nw.ge.num2e) then
c
c     writing out a block
c
_IFN1(iv)                  call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)                 call pak4v(labij,gout(num2e+1))
                  call put(gout,m511,ifilo)
_IFN1(iv)                  do 50 iiii = 1 , 1360
_IFN1(iv)                     labout(iiii) = 0
_IFN1(iv) 50               continue
_IF1(iv)                 call izero(680,labij,1)
                  ib3 = ib3 + 1
                  nw = 0
               end if
            end if
 60      continue
 70   continue
 80   if (nw.ne.0) then
_IFN1(iv)         call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)         call pak4v(labij,gout(num2e+1))
         call put(gout,m511,ifilo)
_IFN1(iv)         do 90 iiii = 1 , 1360
_IFN1(iv)            labout(iiii) = 0
_IFN1(iv) 90      continue
_IF1(iv)         call izero(680,labij,1)
         ib3 = ib3 + 1
      end if
      ib4 = ib3 - 1
c
c     sorting completed
c
      ib3 = iblkb + iblll*nat3
c      derivatives of overlap matrix section 14 of fockfile
c
      ibs = iochf(14)
      lennew = iky(ncoorb+1)
      newblk = lensec(lennew)
      np = nat3
      i = 0
      j = 0
      k = 0
      l = 0
      do 130 n = 1 , nat
         do 100 jj = 1 , mnij
            bx(jj) = zero
            by(jj) = zero
            bz(jj) = zero
 100     continue
         call rdedx(sx,lennew,ibs,ifockf)
         call reads(sy,lennew,ifockf)
         call reads(sz,lennew,ifockf)
         ibs = ibs + newblk*3
c
c     have just read overlap derivatives sx,sy,sz for
c     one atom.  now scan list of integrals <ij/kl>
c
         call search(ib3,ifilo)
         do 120 ibl = ib3 , ib4
            call find(ifilo)
            call get(gin,nn)
_IFN1(iv)           call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)            call upak8v(gin(num2e+1),i205)
            do 110 int = 1 , nword
_IFN1(iv)               n4 = (int+int) + (int+int)
_IFN1(iv)               i = labs(n4-3)
_IFN1(iv)               j = labs(n4-2)
_IFN1(iv)               k = labs(n4-1)
_IFN1(iv)               l = labs(n4)
_IF1(iv)               i = i205(int)
_IF1(iv)               j = j205(int)
_IF1(iv)               k = k205(int)
_IF1(iv)               l = l205(int)
               gg = -gin(int)
               if (i.eq.j) gg = gg*half
               if (k.eq.l) gg = gg*half
               if (i.eq.k.and.j.eq.l) gg = gg*half
               gg4 = gg*four
               ii = (i-1)*nocca
               jj = (j-1)*nocca
               kk = (k-1)*nocca
               ll = (l-1)*nocca
               iij = ii + j
               iik = ii + k
               iil = ii + l
               iji = jj + i
               ijk = jj + k
               ijl = jj + l
               iki = kk + i
               ikj = kk + j
               ikl = kk + l
               ili = ll + i
               ilj = ll + j
               ilk = ll + k
               i1 = mapie(i)
               j1 = mapie(j)
               k1 = mapie(k)
               l1 = mapie(l)
               nij = iky(i1) + j1
               nik = iky(i1) + k1
               nil = iky(i1) + l1
               njk = iky(j1) + k1
               njl = iky(j1) + l1
               nkl = iky(k1) + l1
               if (j1.gt.i1) nij = iky(j1) + i1
               if (k1.gt.i1) nik = iky(k1) + i1
               if (l1.gt.i1) nil = iky(l1) + i1
               if (k1.gt.j1) njk = iky(k1) + j1
               if (l1.gt.j1) njl = iky(l1) + j1
               if (l1.gt.k1) nkl = iky(l1) + k1
c
               bx(iij) = bx(iij) + gg4*sx(nkl)
               by(iij) = by(iij) + gg4*sy(nkl)
               bz(iij) = bz(iij) + gg4*sz(nkl)
               bx(iji) = bx(iji) + gg4*sx(nkl)
               by(iji) = by(iji) + gg4*sy(nkl)
               bz(iji) = bz(iji) + gg4*sz(nkl)
               bx(ikl) = bx(ikl) + gg4*sx(nij)
               by(ikl) = by(ikl) + gg4*sy(nij)
               bz(ikl) = bz(ikl) + gg4*sz(nij)
               bx(ilk) = bx(ilk) + gg4*sx(nij)
               by(ilk) = by(ilk) + gg4*sy(nij)
               bz(ilk) = bz(ilk) + gg4*sz(nij)
c
               bx(iik) = bx(iik) - gg*sx(njl)
               by(iik) = by(iik) - gg*sy(njl)
               bz(iik) = bz(iik) - gg*sz(njl)
               bx(iil) = bx(iil) - gg*sx(njk)
               by(iil) = by(iil) - gg*sy(njk)
               bz(iil) = bz(iil) - gg*sz(njk)
               bx(ijk) = bx(ijk) - gg*sx(nil)
               by(ijk) = by(ijk) - gg*sy(nil)
               bz(ijk) = bz(ijk) - gg*sz(nil)
               bx(ijl) = bx(ijl) - gg*sx(nik)
               by(ijl) = by(ijl) - gg*sy(nik)
               bz(ijl) = bz(ijl) - gg*sz(nik)
               bx(iki) = bx(iki) - gg*sx(njl)
               by(iki) = by(iki) - gg*sy(njl)
               bz(iki) = bz(iki) - gg*sz(njl)
               bx(ili) = bx(ili) - gg*sx(njk)
               by(ili) = by(ili) - gg*sy(njk)
               bz(ili) = bz(ili) - gg*sz(njk)
               bx(ikj) = bx(ikj) - gg*sx(nil)
               by(ikj) = by(ikj) - gg*sy(nil)
               bz(ikj) = bz(ikj) - gg*sz(nil)
               bx(ilj) = bx(ilj) - gg*sx(nik)
               by(ilj) = by(ilj) - gg*sy(nik)
               bz(ilj) = bz(ilj) - gg*sz(nik)
 110        continue
 120     continue
c
c     have just formed that part of r.h.s. involving
c     product of s' with <ij/kl>
c     store this on stratchfile
c
         call wrt3(bx,mnij,iblkb,ifils)
         call wrt3s(by,mnij,ifils)
         call wrt3s(bz,mnij,ifils)
         iblkb = iblkb + iblll*3
 130  continue
c
c
c
      ibh = iochf(13)
      ibs = iochf(14)
      iblkb = iblks
      do 180 l = 1 , nat3
c
c     read perturbed fock matrix elements (integral contribution
c     only) from fockfile at section iochf(13)
c
         call rdedx(sx,lennew,ibh,ifockf)
c
c     and the overlap derivatives again
c
         call rdedx(sy,lennew,ibs,ifockf)
         call rdedx(bx,mnij,iblkb,ifils)
         ibh = ibh + newblk
         ibs = ibs + newblk
         do 150 j = 1 , nocca
            j1 = mapie(j)
c           do 140 i = 1 , j
            do 140 i = 1 , nocca
               i1 = mapie(i)
               if (i1.gt.j1) then
                  it = iky(i1) + j1
               else
                  it = iky(j1) + i1
               endif
               mt = (i-1)*nocca + j
               bx(mt) = bx(mt) + sx(it) - eval(j1)*sy(it)
 140        continue
 150     continue
         do 170 j = 1 , nocca
            do 160 i = 1 , nocca
               mt = (i-1)*nocca + j
               if (dabs(bx(mt)).lt.smal) bx(mt) = zero
 160        continue
 170     continue
c
c     write complete r.h.s. to scratchfile
c
         call wrt3(bx,mnij,iblkb,ifils)
         iblkb = iblkb + iblll
 180  continue
      call clredx
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine rhscl_ab(bx,by,bz,eval,sx,sy,sz)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
c
c     r h s of chf equations ( nuclear displacements )
c     Calculating the virtual-virtual part of the right-hand-side
c
INCLUDE(common/mapper)
      common/maxlen/maxq
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
_IF(rpagrad)
INCLUDE(common/rpadcom)
_ENDIF
INCLUDE(common/infoa)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
_IFN1(iv)      common/small/labout(1360)
_IF1(iv)      common/small/labij(340),labkl(340)
      common/blkin/gin(510),nword
      common/out/gout(510),nw
INCLUDE(common/atmblk)
      dimension bx(*),by(*),bz(*),eval(*),sx(*),sy(*),sz(*)
      data smal/1.0d-20/
      data zero,one,half,four/0.0d0,1.0d0,0.5d0,4.0d0/
c
c     sorts out scf eigenvalues and perturbation matrix elements
c
_IFN1(iv)      do 20 iiii = 1 , 1360
_IFN1(iv)         labout(iiii) = 0
_IFN1(iv) 20   continue
_IF1(iv)      call izero(680,labij,1)
      nplus1 = nocca + 1
      call secget(isect(9),9,isec9)
c
c     read in eigenvalues
c
      call rdedx(eval,lds(isect(9)),isec9,ifild)
c
c     sort out integrals involving 2 virtual m.o.'s
c
      i = 0
      j = 0
      k = 0
      l = 0
      mnij = nocca*nocca
      mnab = (nsa4-nocca)*(nsa4-nocca)
      ifili = nufile(1)
      ifilo = ifils
      ib1 = kblk(1)
      ib2 = nblk(1)
      nw = 0
      nat3 = nat*3
      iblll = lensec(mnab)
      iblkb = iblks + nat3*lensec(mnij)
      ib3 = iblkb + iblll*nat3
      call search(ib1,ifili)
      call wrt3z(iblkb,ifilo,ib3)
      call search(ib3,ifilo)
      do 70 ibl = ib1 , ib2
         call find(ifili)
         call get(gin,nn)
c
c     complete list of two-electron integrals coming
c     in from transformed mainfile.
c     those of form <aj/cl> and <ab/kl> going out
c     on scratchfile (ed7)
c
         if (nn.eq.0) go to 80
_IFN1(iv)        call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(gin(num2e+1),i205)
         do 60 n = 1 , nword
_IFN1(iv)            n4 = (n+n) + (n+n)

_IF(ibm,vax)
            i = i205(n)
            j = j205(n)
            k = k205(n)
            l = l205(n)
_ELSEIF(littleendian)
            i = labs(n4-2)
            j = labs(n4-3)
            k = labs(n4  )
            l = labs(n4-1)
_ELSE
            i = labs(n4-3)
            j = labs(n4-2)
            k = labs(n4-1)
            l = labs(n4)
_ENDIF
            if (i.gt.nocca) then
c              [a*|**]
               if ((j.le.nocca .and. k.gt.nocca .and. l.le.nocca).or.
     +             (j.gt.nocca .and. k.le.nocca)) then
c                 [aj|cl], [ab|kl]
                  nw = nw + 1
                  gout(nw) = gin(n)
_IFN1(iv)                  n4 = (nw+nw) + (nw+nw)
_IFN1(iv)                  labout(n4-3) = i
_IFN1(iv)                  labout(n4-2) = j
_IFN1(iv)                  labout(n4-1) = k
_IFN1(iv)                  labout(n4) = l
_IF1(iv)                  labij(nw) = j + i4096(i)
_IF1(iv)                  labkl(nw) = l + i4096(k)
                  if (nw.ge.num2e) then
c
c     writing out a block
c
_IFN1(iv)                     call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)                    call pak4v(labij,gout(num2e+1))
                     call put(gout,m511,ifilo)
_IFN1(iv)                     do 50 iiii = 1 , 1360
_IFN1(iv)                        labout(iiii) = 0
_IFN1(iv) 50                  continue
_IF1(iv)                    call izero(680,labij,1)
                     ib3 = ib3 + 1
                     nw = 0
                  end if
               end if
            end if
 60      continue
 70   continue
 80   if (nw.ne.0) then
_IFN1(iv)         call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)         call pak4v(labij,gout(num2e+1))
         call put(gout,m511,ifilo)
_IFN1(iv)         do 90 iiii = 1 , 1360
_IFN1(iv)            labout(iiii) = 0
_IFN1(iv) 90      continue
_IF1(iv)         call izero(680,labij,1)
         ib3 = ib3 + 1
      end if
      ib4 = ib3 - 1
c
c     sorting completed
c
      ib3 = iblkb + iblll*nat3
c      derivatives of overlap matrix section 14 of fockfile
c
      ibs = iochf(14)
      lennew = iky(ncoorb+1)
      newblk = lensec(lennew)
      np = nat3
      i = 0
      j = 0
      k = 0
      l = 0
      do 130 n = 1 , nat
         do 100 jj = 1 , mnab
            bx(jj) = zero
            by(jj) = zero
            bz(jj) = zero
 100     continue
         call rdedx(sx,lennew,ibs,ifockf)
         call reads(sy,lennew,ifockf)
         call reads(sz,lennew,ifockf)
         ibs = ibs + newblk*3
c
c     have just read overlap derivatives sx,sy,sz for
c     one atom.  now scan list of integrals <aj/kl>
c
         call search(ib3,ifilo)
         do 120 ibl = ib3 , ib4
            call find(ifilo)
            call get(gin,nn)
_IFN1(iv)            call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)            call upak8v(gin(num2e+1),i205)
            do 110 int = 1 , nword
_IFN1(iv)               n4 = (int+int) + (int+int)
_IFN1(iv)               i = labs(n4-3)
_IFN1(iv)               j = labs(n4-2)
_IFN1(iv)               k = labs(n4-1)
_IFN1(iv)               l = labs(n4)
_IF1(iv)               i = i205(int)
_IF1(iv)               j = j205(int)
_IF1(iv)               k = k205(int)
_IF1(iv)               l = l205(int)
               gg = -gin(int)
               if (i.eq.j) gg = gg*half
               if (k.eq.l) gg = gg*half
               if (i.eq.k.and.j.eq.l) gg = gg*half
               gg4 = gg*four
               ii = (i-nocca-1)*(nsa4-nocca)
               if (j.gt.nocca) then
c                 [ab|kl]
                  jj = (j-nocca-1)*(nsa4-nocca)
                  iij = ii + j-nocca
                  iji = jj + i-nocca
                  k1 = mapie(k)
                  l1 = mapie(l)
                  nkl = iky(k1) + l1
                  if (l1.gt.k1) nkl = iky(l1) + k1
                  bx(iij) = bx(iij) + gg4*sx(nkl)
                  by(iij) = by(iij) + gg4*sy(nkl)
                  bz(iij) = bz(iij) + gg4*sz(nkl)
                  bx(iji) = bx(iji) + gg4*sx(nkl)
                  by(iji) = by(iji) + gg4*sy(nkl)
                  bz(iji) = bz(iji) + gg4*sz(nkl)
               else
c                 [aj|cl]
                  kk = (k-nocca-1)*(nsa4-nocca)
                  iik = ii + k-nocca
                  iki = kk + i-nocca
                  j1 = mapie(j)
                  l1 = mapie(l)
                  njl = iky(j1) + l1
                  if (l1.gt.j1) njl = iky(l1) + j1
                  bx(iik) = bx(iik) - gg*sx(njl)
                  by(iik) = by(iik) - gg*sy(njl)
                  bz(iik) = bz(iik) - gg*sz(njl)
                  bx(iki) = bx(iki) - gg*sx(njl)
                  by(iki) = by(iki) - gg*sy(njl)
                  bz(iki) = bz(iki) - gg*sz(njl)
               endif
 110        continue
 120     continue
c
c     have just formed that part of r.h.s. involving
c     product of s' with <ij/kl>
c     store this on stratchfile
c
         call wrt3(bx,mnab,iblkb,ifils)
         call wrt3s(by,mnab,ifils)
         call wrt3s(bz,mnab,ifils)
         iblkb = iblkb + iblll*3
 130  continue
c
c
c
      ibh = iochf(13)
      ibs = iochf(14)
      iblkb = iblks + nat3*lensec(mnij)
c
      do 180 l = 1 , nat3
c
c     read perturbed fock matrix elements (integral contribution
c     only) from fockfile at section iochf(13)
c
         call rdedx(sx,lennew,ibh,ifockf)
c
c     and the overlap derivatives again
c
         call rdedx(sy,lennew,ibs,ifockf)
         call rdedx(bx,mnab,iblkb,ifils)
         ibh = ibh + newblk
         ibs = ibs + newblk
         do 150 j = nplus1 , nsa4
            j1 = mapie(j)
            do 140 i = nplus1 , nsa4
               i1 = mapie(i)
               if (i1.gt.j1) then
                  it = iky(i1) + j1
               else
                  it = iky(j1) + i1
               endif
               mt = (i-nocca-1)*(nsa4-nocca) + j-nocca
               bx(mt) = bx(mt) + sx(it) - eval(j1)*sy(it)
 140        continue
 150     continue
         do 170 j = nplus1 , nsa4
            do 160 i = nplus1 , nsa4
               mt = (i-nocca-1)*(nsa4-nocca) + j-nocca
               if (dabs(bx(mt)).lt.smal) bx(mt) = zero
 160        continue
 170     continue
c
c
c     write complete r.h.s. to scratchfile
c
         call wrt3(bx,mnab,iblkb,ifils)
         iblkb = iblkb + iblll
 180  continue
      call clredx
      return
      end
c
c-----------------------------------------------------------------------
c
_ENDIF
      subroutine rhscl(eps,bx,by,bz,eval,sx,sy,sz)
      implicit REAL  (a-h,o-z)
c
c     r h s of chf equations ( nuclear displacements )
c
INCLUDE(common/sizes)
_IF(rpagrad)
INCLUDE(common/rpadcom)
_ENDIF
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
INCLUDE(common/mapper)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/atmblk)
      common/maxlen/maxq
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
_IFN1(iv)      common/small/labout(1360)
_IF1(iv)      common/small/labij(340),labkl(340)
      common/blkin/gin(510),nword
      common/out/gout(510),nw
      dimension eps(*),bx(*),by(*),bz(*),eval(*),sx(*),sy(*),sz(*)
      data smal/1.0d-20/
      data zero,one,half,four/0.0d0,1.0d0,0.5d0,4.0d0/
c
_IF(ccpdft)
      hf_wght = CD_HF_exchange_weight()
_ENDIF
c
c     sorts out scf eigenvalues and perturbation matrix elements
c
_IFN1(iv)      do 20 iiii = 1 , 1360
_IFN1(iv)         labout(iiii) = 0
_IFN1(iv) 20   continue
_IF1(iv)      call izero(680,labij,1)
      nplus1 = nocca + 1
      call secget(isect(9),9,isec9)
c
c     read in eigenvalues
c
      call rdedx(eval,lds(isect(9)),isec9,ifild)
      do 40 ii = 1 , nocca
         i1 = mapie(ii)
         do 30 jj = nplus1 , nsa4
            j1 = mapie(jj)
            it = (jj-nocca-1)*nocca + ii
            eps(it) = one/(eval(j1)-eval(i1))
 30      continue
 40   continue
c
c     sort out integrals involving one virtual m.o.
c
      i = 0
      j = 0
      k = 0
      l = 0
      ifili = nufile(1)
      ifilo = ifils
      ib1 = kblk(1)
      ib2 = nblk(1)
      nw = 0
      nat3 = nat*3
      iblll = lensec(mn)
_IF(rpagrad)
      mnij = nocca*nocca
      mnab = (nsa4-nocca)*(nsa4-nocca)
      if (orpagrad) then
c
c        Account for storage of core-core and virtual-virtual parts
c        of the right-hand-sides
c
         iblkb = iblks + (lensec(mnij)+lensec(mnab))*nat3
      else
         iblkb = iblks
      endif
_ELSE
      iblkb = iblks
_ENDIF
      ib3 = iblkb + iblll*nat3
      call search(ib1,ifili)
      call wrt3z(iblkb,ifilo,ib3)
      call search(ib3,ifilo)
      do 70 ibl = ib1 , ib2
         call find(ifili)
         call get(gin,nn)
c
c     complete list of two-electron integrals coming
c     in from transformed mainfile.
c     those of form <aj/kl> going out
c     on scratchfile (ed7)
c
         if (nn.eq.0) go to 80
_IFN1(iv)        call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(gin(num2e+1),i205)
         do 60 n = 1 , nword
_IFN1(iv)            n4 = (n+n) + (n+n)

_IF(ibm,vax)
            i = i205(n)
            j = j205(n)
            k = k205(n)
            l = l205(n)
_ELSEIF(littleendian)
            i = labs(n4-2)
            j = labs(n4-3)
            k = labs(n4  )
            l = labs(n4-1)
_ELSE
            i = labs(n4-3)
            j = labs(n4-2)
            k = labs(n4-1)
            l = labs(n4)
_ENDIF
            if (i.gt.nocca) then
               if (j.le.nocca .and. k.le.nocca .and. l.le.nocca) then
                  nw = nw + 1
                  gout(nw) = gin(n)
_IFN1(iv)                  n4 = (nw+nw) + (nw+nw)
_IFN1(iv)                  labout(n4-3) = i
_IFN1(iv)                  labout(n4-2) = j
_IFN1(iv)                  labout(n4-1) = k
_IFN1(iv)                  labout(n4) = l
_IF1(iv)                  labij(nw) = j + i4096(i)
_IF1(iv)                  labkl(nw) = l + i4096(k)
                  if (nw.ge.num2e) then
c
c
c     writing out a block
c
_IFN1(iv)                     call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)                     call pak4v(labij,gout(num2e+1))
                     call put(gout,m511,ifilo)
_IFN1(iv)                     do 50 iiii = 1 , 1360
_IFN1(iv)                        labout(iiii) = 0
_IFN1(iv) 50                  continue
_IF1(iv)                    call izero(680,labij,1)
                     ib3 = ib3 + 1
                     nw = 0
                  end if
               end if
            end if
 60      continue
 70   continue
 80   if (nw.ne.0) then
_IFN1(iv)         call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)         call pak4v(labij,gout(num2e+1))
         call put(gout,m511,ifilo)
_IFN1(iv)         do 90 iiii = 1 , 1360
_IFN1(iv)            labout(iiii) = 0
_IFN1(iv) 90      continue
_IF1(iv)         call izero(680,labij,1)
         ib3 = ib3 + 1
      end if
      ib4 = ib3 - 1
c
c
c     sorting completed
c
c
      ib3 = iblkb + iblll*nat3
c      derivatives of overlap matrix section 14 of fockfile
c
      ibs = iochf(14)
      lennew = iky(ncoorb+1)
      newblk = lensec(lennew)
      np = nat3
      i = 0
      j = 0
      k = 0
      l = 0
      do 130 n = 1 , nat
         do 100 jj = 1 , mn
            bx(jj) = zero
            by(jj) = zero
            bz(jj) = zero
 100     continue
         call rdedx(sx,lennew,ibs,ifockf)
         call reads(sy,lennew,ifockf)
         call reads(sz,lennew,ifockf)
         ibs = ibs + newblk*3
c
c     have just read overlap derivatives sx,sy,sz for
c     one atom.  now scan list of integrals <aj/kl>
c
         call search(ib3,ifilo)
         do 120 ibl = ib3 , ib4
            call find(ifilo)
            call get(gin,nn)
_IFN1(iv)            call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)            call upak8v(gin(num2e+1),i205)
            do 110 int = 1 , nword
_IFN1(iv)               n4 = (int+int) + (int+int)
_IFN1(iv)               i = labs(n4-3)
_IFN1(iv)               j = labs(n4-2)
_IFN1(iv)               k = labs(n4-1)
_IFN1(iv)               l = labs(n4)
_IF1(iv)               i = i205(int)
_IF1(iv)               j = j205(int)
_IF1(iv)               k = k205(int)
_IF1(iv)               l = l205(int)
               gg = -gin(int)
               if (k.eq.l) gg = gg*half
               gg4 = gg*four
               ii = (i-nocca-1)*nocca
               nij = ii + j
               nik = ii + k
               nil = ii + l
               j1 = mapie(j)
               k1 = mapie(k)
               l1 = mapie(l)
               nkl = iky(k1) + l1
               njk = iky(j1) + k1
               njl = iky(j1) + l1
               if (k1.gt.j1) njk = iky(k1) + j1
               if (l1.gt.j1) njl = iky(l1) + j1
               bx(nij) = bx(nij) + gg4*sx(nkl)
               by(nij) = by(nij) + gg4*sy(nkl)
               bz(nij) = bz(nij) + gg4*sz(nkl)
_IF(ccpdft)
               gg = gg*hf_wght
_ENDIF
               bx(nik) = bx(nik) - gg*sx(njl)
               by(nik) = by(nik) - gg*sy(njl)
               bz(nik) = bz(nik) - gg*sz(njl)
               bx(nil) = bx(nil) - gg*sx(njk)
               by(nil) = by(nil) - gg*sy(njk)
               bz(nil) = bz(nil) - gg*sz(njk)
 110        continue
 120     continue
c
c     have just formed that part of r.h.s. involving
c     product of s' with <ij/kl>
c     store this on stratchfile
c
         call wrt3(bx,mn,iblkb,ifils)
         call wrt3s(by,mn,ifils)
         call wrt3s(bz,mn,ifils)
         iblkb = iblkb + iblll*3
 130  continue
c
c
c
      ibh = iochf(13)
      ibs = iochf(14)
_IF(rpagrad)
c     mnij = nocca*nocca
c     mnab = nsa4*nsa4
      if (orpagrad) then
c
c        Account for storage of core-core and virtual-virtual parts
c        of the right-hand-sides
c
         iblkb = iblks + (lensec(mnij)+lensec(mnab))*nat3
      else
         iblkb = iblks
      endif
_ELSE
      iblkb = iblks
_ENDIF
      do 180 l = 1 , nat3
c
c     read perturbed fock matrix elements (integral contribution
c     only) from fockfile at section iochf(13)
c
         call rdedx(sx,lennew,ibh,ifockf)
c
c     and the overlap derivatives again
c
         call rdedx(sy,lennew,ibs,ifockf)
         call rdedx(bx,mn,iblkb,ifils)
         ibh = ibh + newblk
         ibs = ibs + newblk
         do 150 j = 1 , nocca
            j1 = mapie(j)
            do 140 i = nplus1 , nsa4
               i1 = mapie(i)
               it = iky(i1) + j1
               mt = (i-nocca-1)*nocca + j
               bx(mt) = bx(mt) + sx(it) - eval(j1)*sy(it)
 140        continue
 150     continue
         do 170 j = 1 , nocca
            do 160 i = nplus1 , nsa4
               mt = (i-nocca-1)*nocca + j
               if (dabs(bx(mt)).lt.smal) bx(mt) = zero
 160        continue
 170     continue
c
c
c     write complete r.h.s. to scratchfile
c
         call wrt3(bx,mn,iblkb,ifils)
         iblkb = iblkb + iblll
 180  continue
      call clredx
      return
      end
_EXTRACT(rhsgvb,mips4)
      subroutine rhsgvb(mapnr,bx,by,bz,epsx,epsy,epsz,eta,zeta,sx,
     1                        sy,sz,acore,alpha,beta,iblok,iblok2)
c
c      right hand side of general scf chf equations
c
      implicit REAL  (a-h,o-z)
      dimension epsx(*),bx(*),by(*),bz(*),epsy(*),sx(*),sy(*),sz(*)
      dimension epsz(*),eta(*),alpha(11,*),beta(11,*),
     1          zeta(nx,njk1)
      dimension mapnr(*)
INCLUDE(common/sizes)
INCLUDE(common/cigrad)
      logical acore
INCLUDE(common/ghfblk)
INCLUDE(common/mapper)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/atmblk)
      common/maxlen/maxq
      common/blkin/gin(510),nword
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      integer xat,x
      common/mpshl/ns(maxorb)
c
      data half/0.5d0/
      data two / 2.0d0/
c
      ioff(i) = i*(i-1)/2
c
c     sorts out scf eigenvalues and perturbation matrix elements
c
c
_IFN1(iv)      do 20 iiii = 1 , 1360
_IFN1(iv)         labs(iiii) = 0
_IFN1(iv) 20   continue
_IF1(iv)      call setsto(1360,0,i205)
      iblkb = iblks
      call vclr(bx,1,mn*nat)
      call vclr(by,1,mn*nat)
      call vclr(bz,1,mn*nat)
c     mtype = 0
      ibh = iochf(17)
      ibs = iochf(14)
      iblll = lensec(mn)
      numsq = ncoorb*ncoorb
      newblk = lensec(numsq)
c
      if (.not.acore) call caserr(' increase core to allow for b ')
c
      do 50 xat = 1 , nat
         call rdedx(sx,numsq,ibh,ifockf)
         call reads(sy,numsq,ifockf)
         call reads(sz,numsq,ifockf)
c
         ibh = ibh + newblk*3
c
         ij = 0
         do 40 i = 1 , num
            do 30 j = 1 , i
               ij = ij + 1
               if (mapnr(ij).gt.0) then
                  mp = mapnr(ij) + (xat-1)*mn
                  bx(mp) = -two*(sx(i+(j-1)*num)-sx(j+(i-1)*num))
                  by(mp) = -two*(sy(i+(j-1)*num)-sy(j+(i-1)*num))
                  bz(mp) = -two*(sz(i+(j-1)*num)-sz(j+(i-1)*num))
               end if
 30         continue
 40      continue
 50   continue
c
      newblk = lensec(nx)
      do 60 xat = 1 , nat
         mx = 1 + (xat-1)*nx
         call rdedx(sx(mx),nx,ibs,ifockf)
         call reads(sy(mx),nx,ifockf)
         call reads(sz(mx),nx,ifockf)
         ibs = ibs + newblk*3
 60   continue
c
c   for historical reasons the scratchfile is set up in the order
c
c   b : mnnr*nat*3
c
c   xir - xri : xir is the ci lagrangian over independent pairs : mnnr
c
c   zir : solution of atz = xir-xri : mnnr
c
c   eta : nx
c
c   zeta : nx*njk1
c
c     lenblk = lensec(mn)
      call rdedx(eta,nx,iblok,ifils)
c
      call rdedx(zeta,nx*njk1,iblok2,ifils)
c
      do 100 xat = 1 , nat
         ijx = 0
         do 90 i = 1 , ncoorb
            do 80 j = 1 , i
               ijx = ijx + 1
               if (mapnr(ijx).gt.0) then
                  mp = mapnr(ijx) + (xat-1)*mn
                  do 70 k = 1 , ncoorb
                     jkx = ioff(j) + k
                     ikx = ioff(i) + k
                     if (k.gt.j) jkx = ioff(k) + j
                     if (k.gt.i) ikx = ioff(k) + i
                     bx(mp) = bx(mp) + sx(jkx+(xat-1)*nx)
     +                        *(eta(ikx)-zeta(ikx,ns(j)))
     +                        - sx(ikx+(xat-1)*nx)
     +                        *(eta(jkx)-zeta(jkx,ns(i)))
                     by(mp) = by(mp) + sy(jkx+(xat-1)*nx)
     +                        *(eta(ikx)-zeta(ikx,ns(j)))
     +                        - sy(ikx+(xat-1)*nx)
     +                        *(eta(jkx)-zeta(jkx,ns(i)))
                     bz(mp) = bz(mp) + sz(jkx+(xat-1)*nx)
     +                        *(eta(ikx)-zeta(ikx,ns(j)))
     +                        - sz(ikx+(xat-1)*nx)
     +                        *(eta(jkx)-zeta(jkx,ns(i)))
 70               continue
               end if
 80         continue
 90      continue
 100  continue
      i = 0
      j = 0
      k = 0
      l = 0
      ifili = nufile(1)
      ib1 = kblk(1)
      ib2 = nblk(1)
c     nat3 = nat*3
      call search(ib1,ifili)
      do 200 ibl = ib1 , ib2
         call find(ifili)
         call get(gin,nw)
c
c     complete list of two-electron integrals coming
c     in from transformed mainfile.
c
         if (nw.ne.0) then
_IFN1(iv)        call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(gin(num2e+1),i205)
            do 190 n = 1 , nword
_IF(ibm,vax)
               i = i205(n)
               j = j205(n)
               k = k205(n)
               l = l205(n)
_ELSEIF(littleendian)
               i = labs(4*n-2)
               j = labs(4*n-3)
               k = labs(4*n  )
               l = labs(4*n-1)
_ELSE
               i = labs(4*n-3)
               j = labs(4*n-2)
               k = labs(4*n-1)
               l = labs(4*n)
_ENDIF
               ij = ioff(i) + j
               kl = ioff(k) + l
               ik = ioff(i) + k
               jl = ioff(j) + l
               if (l.gt.j) jl = ioff(l) + j
               il = ioff(i) + l
               jk = ioff(j) + k
               if (k.gt.j) jk = ioff(k) + j
c
c
c
c   type 6 : i = j = k = l
c
               if (ijkltp(i,j,k,l).ne.1) then
c
c
c   l virtual implies 3 or more virtual orbitals
c
                  if (ns(l).le.njk) then
c
c   type 2 : i = j = k > l
c
                     if (ijkltp(i,j,k,l).eq.2) then
                        if (mapnr(il).gt.0) then
                           mp = mapnr(il)
                           do 110 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+ij)
     +                           *two*(alpha(ns(i),ns(i))
     +                           -alpha(ns(i),ns(l))+beta(ns(i),ns(i))
     +                           -beta(ns(i),ns(l)))*gin(n)
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+ij)
     +                           *two*(alpha(ns(i),ns(i))
     +                           -alpha(ns(i),ns(l))+beta(ns(i),ns(i))
     +                           -beta(ns(i),ns(l)))*gin(n)
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+ij)
     +                           *two*(alpha(ns(i),ns(i))
     +                           -alpha(ns(i),ns(l))+beta(ns(i),ns(i))
     +                           -beta(ns(i),ns(l)))*gin(n)
 110                       continue
                        end if
                        go to 190
                     end if
c
c
c   type 3 : i > j = k = l
c
                     if (ijkltp(i,j,k,l).eq.3) then
                        if (mapnr(il).gt.0) then
                           mp = mapnr(il)
                           do 120 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+jk)
     +                           *two*(alpha(ns(i),ns(l))
     +                           -alpha(ns(l),ns(l))+beta(ns(i),ns(l))
     +                           -beta(ns(l),ns(l)))*gin(n)
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+jk)
     +                           *two*(alpha(ns(i),ns(l))
     +                           -alpha(ns(l),ns(l))+beta(ns(i),ns(l))
     +                           -beta(ns(l),ns(l)))*gin(n)
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+jk)
     +                           *two*(alpha(ns(i),ns(l))
     +                           -alpha(ns(l),ns(l))+beta(ns(i),ns(l))
     +                           -beta(ns(l),ns(l)))*gin(n)
 120                       continue
                        end if
                        go to 190
                     end if
c
c
c   type 4 : i = j > k = l
c
                     if (ijkltp(i,j,k,l).ge.4) then
                        gg = gin(n)
                        if (i.eq.j) gg = gg*half
                        if (k.eq.l) gg = gg*half
                        if (i.eq.k .and. j.eq.l) gg = gg*half
c
c   type 5 : i = k > j = l
c   type 6 : i = j > k > l
c   type 7 : i = k > j > l
c   type 8 : i > j = k > l
c   type 10 : i > j > k = l
c   type 11 : i > k = l > j
c   type 12 : i > j > k > l
c   type 13 : i > k > j > l
c   type 14 : i > k > l > j
c
                        if (mapnr(ij).gt.0) then
                           mp = mapnr(ij)
                           do 130 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+kl)
     +                           *two*aijklx(i,j,k,l,ns,alpha)*gg
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+kl)
     +                           *two*aijklx(i,j,k,l,ns,alpha)*gg
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+kl)
     +                           *two*aijklx(i,j,k,l,ns,alpha)*gg
 130                       continue
                        end if
                        if (mapnr(kl).gt.0) then
                           mp = mapnr(kl)
                           do 140 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+ij)
     +                           *two*aijklx(k,l,i,j,ns,alpha)*gg
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+ij)
     +                           *two*aijklx(k,l,i,j,ns,alpha)*gg
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+ij)
     +                           *two*aijklx(k,l,i,j,ns,alpha)*gg
 140                       continue
                        end if
                        if (mapnr(il).gt.0) then
                           mp = mapnr(il)
                           do 150 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+jk)
     +                           *aijklx(i,l,j,k,ns,beta)*gg
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+jk)
     +                           *aijklx(i,l,j,k,ns,beta)*gg
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+jk)
     +                           *aijklx(i,l,j,k,ns,beta)*gg
 150                       continue
                        end if
                        if (mapnr(ik).gt.0) then
                           mp = mapnr(ik)
                           do 160 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+jl)
     +                           *aijklx(i,k,j,l,ns,beta)*gg
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+jl)
     +                           *aijklx(i,k,j,l,ns,beta)*gg
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+jl)
     +                           *aijklx(i,k,j,l,ns,beta)*gg
 160                       continue
                        end if
                        if (mapnr(jl).gt.0) then
                           mp = mapnr(jl)
                           jsw = j
                           lsw = l
                           if (j.lt.l) then
                              jsw = l
                              lsw = j
                           end if
                           do 170 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+ik)
     +                           *aijklx(jsw,lsw,i,k,ns,beta)*gg
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+ik)
     +                           *aijklx(jsw,lsw,i,k,ns,beta)*gg
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+ik)
     +                           *aijklx(jsw,lsw,i,k,ns,beta)*gg
 170                       continue
                        end if
                        if (mapnr(jk).gt.0) then
                           mp = mapnr(jk)
                           jsw = j
                           ksw = k
                           if (j.lt.k) then
                              jsw = k
                              ksw = j
                           end if
                           do 180 x = 1 , nat
                              bx(mp+(x-1)*mn) = bx(mp+(x-1)*mn)
     +                           + sx((x-1)*nx+il)
     +                           *aijklx(jsw,ksw,i,l,ns,beta)*gg
                              by(mp+(x-1)*mn) = by(mp+(x-1)*mn)
     +                           + sy((x-1)*nx+il)
     +                           *aijklx(jsw,ksw,i,l,ns,beta)*gg
                              bz(mp+(x-1)*mn) = bz(mp+(x-1)*mn)
     +                           + sz((x-1)*nx+il)
     +                           *aijklx(jsw,ksw,i,l,ns,beta)*gg
 180                       continue
                        end if
                     end if
                  end if
               end if
c     end if
c
c
c
 190        continue
         end if
c
 200  continue
c
      do 210 x = 1 , nat
         call wrt3(bx(1+(x-1)*mn),mn,iblkb,ifils)
         call wrt3s(by(1+(x-1)*mn),mn,ifils)
         call wrt3s(bz(1+(x-1)*mn),mn,ifils)
         iblkb = iblkb + iblll*3
 210  continue
c
      return
      end
_ENDEXTRACT
      subroutine rhsrhf(eps,b,bb,u,eval,qq)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
c
c     r h s of chf equations ( nuclear displacements)
c
c     logical out
INCLUDE(common/mapper)
      common/maxlen/maxq
c
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
_IFN1(iv)      common/small/labout(1360)
_IF1(iv)      common/small/labij(340),labkl(340)
      common/blkin/gin(510),nword
      common/out/gout(510),nw
INCLUDE(common/atmblk)
INCLUDE(common/prnprn)
      dimension eps(*),b(*),bb(*),u(*),eval(*),qq(*)
      data smal/1.0d-20/
      data zero,one,two,half,four/0.0d0,1.0d0,2.0d0,0.5d0,4.0d0/
c
      ind(i,j) = iky(max(i,j)) + min(i,j)
c
c     sorts out scf eigenvalues and perturbation matrix elements
c
_IFN1(iv)      do 20 iiii = 1 , 1360
_IFN1(iv)         labout(iiii) = 0
_IFN1(iv) 20   continue
_IF1(iv)      call izero(680,labij,1)
c     out = oprn(12)
      nsoc = noccb - nocca
      nvirta = nsa4 - noccb
      nsd = nocca*nsoc
      mn = nocca*nsoc + noccb*nvirta
      ndpls1 = nocca + 1
      ntpls1 = noccb + 1
      call secget(isect(9),9,isec)
      call rdedx(eval,lds(isect(9)),isec,ifild)
      if (nocca.ne.0) then
         do 40 jj = 1 , nocca
            do 30 ii = ndpls1 , nsa4
               it = (ii-ndpls1)*nocca + jj
               eps(it) = one/(eval(mapie(ii))-eval(mapie(jj)))
 30         continue
 40      continue
      end if
      if (noccb.ne.nocca) then
         do 60 jj = ndpls1 , noccb
            do 50 ii = ntpls1 , nsa4
               it = nvirta*nocca + (ii-nsoc-1)*nsoc + jj - nocca
               eps(it) = one/(eval(mapie(ii))-eval(mapie(jj)))
 50         continue
 60      continue
      end if
c
c     sort out integrals contributing to b
c
      i = 0
      j = 0
      k = 0
      l = 0
      ifili = nufile(1)
      ifilo = ifils
      iblkb = iblks
      iblll = lensec(mn)
      nat3 = nat*3
      ib1 = kblk(1)
      ib2 = nblk(1)
      nw = 0
      ib3 = iblks + iblll*nat3
      call search(ib1,ifili)
      call wrt3z(iblkb,ifilo,ib3)
      call search(ib3,ifilo)
      do 90 ibl = ib1 , ib2
         call find(ifili)
         call get(gin,nn)
         if (nn.eq.0) go to 100
         if (nword.eq.0) go to 100
_IFN1(iv)         call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(gin(num2e+1),i205)
         do 80 n = 1 , nword
_IFN1(iv)            n4 = (n+n) + (n+n)
_IF(ibm,vax)
            i = i205(n)
            j = j205(n)
            k = k205(n)
            l = l205(n)
_ELSEIF(littleendian)
            i = labs(n4-2)
            j = labs(n4-3)
            k = labs(n4  )
            l = labs(n4-1)
_ELSE
            i = labs(n4-3)
            j = labs(n4-2)
            k = labs(n4-1)
            l = labs(n4)
_ENDIF

            if (j.le.noccb .and. k.le.noccb .and. i.gt.nocca) then
               if (j.le.nocca .or. k.gt.nocca .or. i.gt.noccb) then
                  if (j.le.nocca .or. i.gt.noccb .or. l.le.nocca) then
                     nw = nw + 1
                     gout(nw) = gin(n)
_IFN1(iv)                     n4 = (nw+nw) + (nw+nw)
_IFN1(iv)                     labout(n4-3) = i
_IFN1(iv)                     labout(n4-2) = j
_IFN1(iv)                     labout(n4-1) = k
_IFN1(iv)                     labout(n4) = l
_IF1(iv)                     labij(nw) = j + i4096(i)
_IF1(iv)                     labkl(nw) = l + i4096(k)
                     if (nw.ge.num2e) then
_IFN1(iv)                        call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)                       call pak4v(labij,gout(num2e+1))
                        call put(gout,m511,ifilo)
_IFN1(iv)                        do 70 iiii = 1 , 1360
_IFN1(iv)                           labout(iiii) = 0
_IFN1(iv) 70                     continue
_IF1(iv)      call izero(680,labij,1)
                        ib3 = ib3 + 1
                        nw = 0
                     end if
                  end if
               end if
            end if
 80      continue
 90   continue
 100  if (nw.ne.0) then
_IFN1(iv)         call pack(gout(num2e+1),lab816,labout,numlab)
_IF1(iv)         call pak4v(labij,gout(num2e+1))
         call put(gout,m511,ifilo)
_IFN1(iv)         do 110 iiii = 1 , 1360
_IFN1(iv)            labout(iiii) = 0
_IFN1(iv) 110     continue
_IF1(iv)      call izero(680,labij,1)
         ib3 = ib3 + 1
      end if
      ib4 = ib3 - 1
      ib3 = iblks + iblll*nat3
c
c
c     derivatives of fock matrix elements at section 13
c     derivatives of overlap at section 14
      ibh = iochf(13)
      ibs = iochf(14)
      lennew = iky(ncoorb+1)
      newblk = lensec(lennew)
      np = nat3
      i = 0
      j = 0
      k = 0
      l = 0
      do 150 n = 1 , nat
         do 120 jj = 1 , mn
            b(jj) = zero
            bb(jj) = zero
            u(jj) = zero
 120     continue
         call rdedx(qq,lennew,ibs,ifockf)
         ibs = ibs + newblk
         call rdedx(qq(lennew+1),lennew,ibs,ifockf)
         ibs = ibs + newblk
         call rdedx(qq(lennew+lennew+1),lennew,ibs,ifockf)
         ibs = ibs + newblk
         call actmot(qq(1),nsa4,mapie,iky)
         call actmot(qq(lennew+1),nsa4,mapie,iky)
         call actmot(qq(lennew+lennew+1),nsa4,mapie,iky)
         call search(ib3,ifilo)
         do 140 ibl = ib3 , ib4
            call find(ifilo)
            call get(gin,nn)
_IFN1(iv)            call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)            call upak8v(gin(num2e+1),i205)
            do 130 int = 1 , nword
_IFN1(iv)               n4 = (int+int) + (int+int)
_IFN1(iv)               i = labs(n4-3)
_IFN1(iv)               j = labs(n4-2)
_IFN1(iv)               k = labs(n4-1)
_IFN1(iv)               l = labs(n4)
_IF1(iv)            i = i205(n)
_IF1(iv)            j = j205(n)
_IF1(iv)            k = k205(n)
_IF1(iv)            l = l205(n)
               gg = -gin(int)
               if (j.le.nocca) then
                  if (k.le.nocca) then
                     if (k.eq.l) gg = gg*half
                     ggd = gg*four
                     ggo = -gg
                     ii = (i-nocca-1)*nocca
                     nij = ii + j
                     nik = ii + k
                     nil = ii + l
                     nkl = iky(k) + l
                     njk = iky(j) + k
                     njl = iky(j) + l
                     if (k.gt.j) njk = iky(k) + j
                     if (l.gt.j) njl = iky(l) + j
                     b(nij) = b(nij) + ggd*qq(nkl)
                     bb(nij) = bb(nij) + ggd*qq(lennew+nkl)
                     u(nij) = u(nij) + ggd*qq(lennew+lennew+nkl)
                     b(nik) = b(nik) + ggo*qq(njl)
                     bb(nik) = bb(nik) + ggo*qq(lennew+njl)
                     u(nik) = u(nik) + ggo*qq(lennew+lennew+njl)
                     b(nil) = b(nil) + ggo*qq(njk)
                     bb(nil) = bb(nil) + ggo*qq(lennew+njk)
                     u(nil) = u(nil) + ggo*qq(lennew+lennew+njk)
                  else if (l.le.nocca) then
                     if (i.le.noccb) then
c  (sd/sd)
                        ggd = two*gg
                        ii = (i-nocca-1)*nocca
                        nij = ii + j
                        nkl = iky(k) + l
                        b(nij) = b(nij) + ggd*qq(nkl)
                        bb(nij) = bb(nij) + ggd*qq(lennew+nkl)
                        u(nij) = u(nij) + ggd*qq(lennew+lennew+nkl)
                        if (i.ne.k .or. j.ne.l) then
                           kk = (k-nocca-1)*nocca
                           nkl = kk + l
                           nij = ind(i,j)
                           b(nkl) = b(nkl) + ggd*qq(nij)
                           bb(nkl) = bb(nkl) + ggd*qq(lennew+nij)
                           u(nkl) = u(nkl) + ggd*qq(lennew+lennew+nij)
                        end if
                     else
c  (vd/sd)
                        ggo = -gg
                        ggd = two*gg
                        ggos = -half*gg
                        iis = (i-nocca-1)*nocca
                        ii = nvirta*nocca + (i-nsoc-1)*nsoc - nocca
                        nik = ii + k
                        nij = iis + j
                        nil = iis + l
                        njl = iky(j) + l
                        if (l.gt.j) njl = iky(l) + j
                        b(nik) = b(nik) + ggo*qq(njl)
                        bb(nik) = bb(nik) + ggo*qq(lennew+njl)
                        u(nik) = u(nik) + ggo*qq(lennew+lennew+njl)
                        b(nij) = b(nij) + ggd*qq(ind(k,l))
                        bb(nij) = bb(nij) + ggd*qq(lennew+ind(k,l))
                        u(nij) = u(nij) + ggd*qq(lennew+lennew+ind(k,l))
                        b(nil) = b(nil) + ggos*qq(ind(j,k))
                        bb(nil) = bb(nil) + ggos*qq(lennew+ind(k,j))
                        u(nil) = u(nil)
     +                           + ggos*qq(lennew+lennew+ind(k,j))
                     end if
                  else if (i.le.noccb) then
c  (sd/ss)
                     if (k.eq.l) gg = gg*half
                     ggd = gg*two
                     ii = (i-nocca-1)*nocca
                     nij = ii + j
                     nkl = iky(k) + l
                     b(nij) = b(nij) + ggd*qq(nkl)
                     bb(nij) = bb(nij) + ggd*qq(lennew+nkl)
                     u(nij) = u(nij) + ggd*qq(lennew+lennew+nkl)
                  else
c  (vd/ss)
                     ggos = -gg
                     if (k.eq.l) gg = gg*half
                     ggd = gg*two
                     ii = (i-nocca-1)*nocca
                     iis = nvirta*nocca + (i-nsoc-1)*nsoc - nocca
                     nik = iis + k
                     nil = iis + l
                     nij = ii + j
                     nkl = iky(k) + l
                     b(nij) = b(nij) + ggd*qq(nkl)
                     bb(nij) = bb(nij) + ggd*qq(lennew+nkl)
                     u(nij) = u(nij) + ggd*qq(lennew+lennew+nkl)
                     b(nik) = b(nik) + ggos*qq(ind(j,l))
                     bb(nik) = bb(nik) + ggos*qq(lennew+ind(j,l))
                     u(nik) = u(nik) + ggos*qq(lennew+lennew+ind(j,l))
                     if (k.ne.l) then
                        b(nil) = b(nil) + ggos*qq(ind(j,k))
                        bb(nil) = bb(nil) + ggos*qq(lennew+ind(j,k))
                        u(nil) = u(nil)
     +                           + ggos*qq(lennew+lennew+ind(j,k))
                     end if
                  end if
               else if (i.le.noccb) then
                  if (i.eq.j) gg = gg*half
                  ggd = gg*two
                  kk = (k-nocca-1)*nocca
                  nkl = kk + l
                  nij = iky(i) + j
                  b(nkl) = b(nkl) + ggd*qq(nij)
                  bb(nkl) = bb(nkl) + ggd*qq(lennew+nij)
                  u(nkl) = u(nkl) + ggd*qq(lennew+lennew+nij)
               else if (k.le.nocca) then
c  (vs/dd)
                  ggos = -half*gg
                  if (k.eq.l) gg = gg*half
                  ggd = gg*four
                  ii = nvirta*nocca + (i-nsoc-1)*nsoc - nocca
                  iis = (i-nocca-1)*nocca
                  nik = iis + k
                  nil = iis + l
                  nij = ii + j
                  nkl = iky(k) + l
                  b(nij) = b(nij) + ggd*qq(nkl)
                  bb(nij) = bb(nij) + ggd*qq(lennew+nkl)
                  u(nij) = u(nij) + ggd*qq(lennew+lennew+nkl)
                  b(nik) = b(nik) + ggos*qq(ind(j,l))
                  bb(nik) = bb(nik) + ggos*qq(lennew+ind(j,l))
                  u(nik) = u(nik) + ggos*qq(lennew+lennew+ind(j,l))
                  if (k.ne.l) then
                     b(nil) = b(nil) + ggos*qq(ind(k,j))
                     bb(nil) = bb(nil) + ggos*qq(lennew+ind(k,j))
                     u(nil) = u(nil) + ggos*qq(lennew+lennew+ind(k,j))
                  end if
               else if (l.le.nocca) then
c (vs/sd)
                  ggo = -half*gg
                  ggd = two*gg
                  ggos = -gg
                  iis = nvirta*nocca + (i-nsoc-1)*nsoc - nocca
                  ii = (i-nocca-1)*nocca
                  nil = ii + l
                  nij = iis + j
                  nik = iis + k
                  njk = iky(j) + k
                  if (k.gt.j) njk = iky(k) + j
                  b(nil) = b(nil) + ggo*qq(njk)
                  bb(nil) = bb(nil) + ggo*qq(lennew+njk)
                  u(nil) = u(nil) + ggo*qq(lennew+lennew+njk)
                  b(nij) = b(nij) + ggd*qq(ind(k,l))
                  bb(nij) = bb(nij) + ggd*qq(lennew+ind(k,l))
                  u(nij) = u(nij) + ggd*qq(lennew+lennew+ind(k,l))
                  b(nik) = b(nik) + ggos*qq(ind(j,l))
                  bb(nik) = bb(nik) + ggos*qq(lennew+ind(j,l))
                  u(nik) = u(nik) + ggos*qq(lennew+lennew+ind(j,l))
               else
                  if (k.eq.l) gg = gg*half
                  ggd = gg*two
                  ggo = -gg
                  ii = nvirta*nocca + (i-nsoc-1)*nsoc - nocca
                  nij = ii + j
                  nik = ii + k
                  nil = ii + l
                  nkl = iky(k) + l
                  njk = iky(j) + k
                  njl = iky(j) + l
                  if (k.gt.j) njk = iky(k) + j
                  if (l.gt.j) njl = iky(l) + j
                  b(nij) = b(nij) + ggd*qq(nkl)
                  bb(nij) = bb(nij) + ggd*qq(lennew+nkl)
                  u(nij) = u(nij) + ggd*qq(lennew+lennew+nkl)
                  b(nik) = b(nik) + ggo*qq(njl)
                  bb(nik) = bb(nik) + ggo*qq(lennew+njl)
                  u(nik) = u(nik) + ggo*qq(lennew+lennew+njl)
                  b(nil) = b(nil) + ggo*qq(njk)
                  bb(nil) = bb(nil) + ggo*qq(lennew+njk)
                  u(nil) = u(nil) + ggo*qq(lennew+lennew+njk)
               end if
 130        continue
 140     continue
         call wrt3(b,mn,iblkb,ifils)
         iblkb = iblkb + iblll
         call wrt3(bb,mn,iblkb,ifils)
         iblkb = iblkb + iblll
         call wrt3(u,mn,iblkb,ifils)
         iblkb = iblkb + iblll
 150  continue
c
c
      ibs = iochf(14)
      iblkb = iblks
      ioffk = lennew + lennew + 1
      ioffk1 = ioffk + lennew
      ioffk0 = ioffk - 1
      ioffka = ioffk1 - 1
      call secget(isect(43),43,iblok)
      call rdedx(qq(ioffk),lds(isect(43)),iblok,ifild)
      lenblk = lensec(nx)
      iblkk = iochf(13) + nat3*lenblk
      do 260 l = 1 , nat3
         call rdedx(qq,lennew,ibh,ifockf)
         call rdedx(qq(lennew+1),lennew,ibs,ifockf)
         call rdedx(b,mn,iblkb,ifils)
         call rdedx(qq(ioffk1),lennew,iblkk,ifockf)
         call actmot(qq(1),nsa4,mapie,iky)
         call actmot(qq(lennew+1),nsa4,mapie,iky)
         call actmot(qq(ioffk1),nsa4,mapie,iky)
         iblkk = iblkk + lenblk
         ibh = ibh + newblk
         ibs = ibs + newblk
         if (nocca.ne.0) then
            do 190 j = 1 , nocca
               do 180 i = ndpls1 , nsa4
                  xxk = 1.0d0
                  if (i.gt.noccb) xxk = 2.0d0
                  it = iky(i) + j
                  mt = (i-nocca-1)*nocca + j
                  b(mt) = b(mt) + qq(it) - eval(j)*qq(lennew+it)
                  if (i.le.noccb) b(mt) = b(mt) + qq(ioffka+ind(i,j))
                  do 160 k = 1 , nocca
                     ik = iky(i) + k
                     b(mt) = b(mt) + xxk*qq(ind(j,k)+ioffk0)
     +                       *qq(lennew+ik)
 160              continue
                  if (nocca.ne.noccb) then
                     if (i.gt.noccb) then
                        do 170 k = ndpls1 , noccb
                           ik = iky(i) + k
                           b(mt) = b(mt) + qq(ind(k,j)+ioffk0)
     +                             *qq(lennew+ik)
 170                    continue
                     end if
                  end if
 180           continue
 190        continue
         end if
         if (nocca.ne.noccb) then
            do 230 j = ndpls1 , noccb
               do 220 i = ntpls1 , nsa4
                  it = iky(i) + j
                  mt = nvirta*nocca + (i-nsoc-1)*nsoc + j - nocca
                  b(mt) = b(mt) - qq(ind(i,j)+ioffka) + qq(it) - eval(j)
     +                    *qq(lennew+it)
                  do 200 k = 1 , nocca
                     ik = iky(i) + k
                     jk = iky(j) + k
                     b(mt) = b(mt) + 2.0d0*qq(ind(j,k)+ioffk0)
     +                       *qq(lennew+ik) + qq(ind(k,i)+ioffk0)
     +                       *qq(lennew+jk)
 200              continue
                  do 210 k = ndpls1 , noccb
                     ik = iky(i) + k
                     b(mt) = b(mt) + qq(ind(j,k)+ioffk0)*qq(lennew+ik)
 210              continue
 220           continue
 230        continue
         end if
c
c
c
         nsv = nsd + nocca*nvirta
         nsd1 = nsd + 1
         do 240 i = nsd1 , nsv
            b(i) = b(i) + b(i)
 240     continue
         do 250 i = 1 , mn
            b(i) = b(i)*0.5d0
            if (dabs(b(i)).lt.smal) b(i) = zero
 250     continue
         call wrt3(b,mn,iblkb,ifils)
         iblkb = iblkb + iblll
 260  continue
      do 270 i = nsd1 , nsv
         eps(i) = eps(i)*0.5d0
 270  continue
      do 280 i = 1 , mn
         eps(i) = eps(i) + eps(i)
 280  continue
      return
      end
      subroutine rhsemp(eps,b,x,mnr)
c
c   constructs right-hand-side of chf for electric and
c   and magnetic perturbations (called RHSIN in CADPAC)
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension eps(*),mnr(*),b(*),x(*)
c
INCLUDE(common/infoa)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/mapper)
      common/mpshl/ns(maxorb)
INCLUDE(common/ghfblk)
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
INCLUDE(common/prnprn)
      character*10 charwall
      character *8 grhf
      data grhf/'grhf'/
      data maxper/50/
c
      data zero,one/0.0d0,1.0d0/
c
c     sorts out scf eigenvalues and perturbation matrix elements
c
c     read in orbital energies
c
      iblkb = iblks
      if (scftyp.ne.grhf) then
         call secget(isect(9),9,iblok)
         call rdedx(x,lds(isect(9)),iblok,ifild)
c
         nsoc = noccb - nocca
         ntpls1 = noccb + 1
         ndpls1 = nocca + 1
         if (nocca.ne.0) then
            do 30 j = 1 , nocca
               do 20 i = ndpls1 , nsa4
                  it = (i-ndpls1)*nocca + j
                  eps(it) = one/(x(mapie(i))-x(mapie(j)))
 20            continue
 30         continue
         end if
         if (noccb.ne.nocca) then
            do 50 j = ndpls1 , noccb
               do 40 i = ntpls1 , nsa4
                  it = nvirta*nocca + (i-nsoc-1)*nsoc + j - nocca
                  eps(it) = one/(x(mapie(i))-x(mapie(j)))
 40            continue
 50         continue
            nsd = nocca*nsoc
            nsv = nsd + nocca*nvirta
            nsd1 = nsd + 1
            do 60 i = nsd1 , nsv
               eps(i) = eps(i)*0.5d0
 60         continue
            do 70 i = 1 , mn
               eps(i) = eps(i) + eps(i)
 70         continue
         end if
      end if
      iblll = lensec(mn)
      lennew = ikyp(nsa4)
c     nword = ikyp(ncoorb)
      np = 0
      do 110 l = 1 , maxper
         if (.not.(opskip(l))) then
            do 80 i = 1 , mn
               b(i) = zero
 80         continue
            if(odebug(30)) write (iwr,6010) pnames(l) , ipsec(l)
            np = np + 1
            jtype = 0
            call secget(ipsec(l),jtype,isec)
            call rdedx(x,lds(ipsec(l)),isec,ifild)
            call ijconr(x,b,lennew,mnr)
            ij = 0
            do 100 i = 1 , nsa4
               do 90 j = 1 , i
                  ij = ij + 1
                  if (ns(i).ne.ns(j)) then
                     nr = mnr(ij)
                     b(nr) = b(nr)*(fjk(ns(j))-fjk(ns(i)))*0.5d0
                  end if
 90            continue
 100        continue
            call wrt3(b,mn,iblkb,ifils)
            iblkb = iblkb + iblll
         end if
 110  continue
      write (iwr,6020) cpulft(1) ,charwall()
      return
 6010 format (1x,'perturbation',4x,a4,' from section',i6)
 6020 format (/1x,'construction of r.h.s. of equations',' complete at',
     +        1x,f8.2,' seconds',a10,' wall')
      end
_IFN(secd_parallel)
      subroutine ovlcl(qq,iqq)
c
c    assemble overlap contribution to closed shell scf second
c    derivatives
c   term involving derivative of lagrangian
c   closed shell case
c
      implicit REAL  (a-h,o-z)
      logical out
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
      common/bufb/e(maxorb),e1(maxorb)
      dimension qq(*),iqq(*)
      common/maxlen/maxq
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
INCLUDE(common/symtry)
c
INCLUDE(common/prnprn)
c
      out = odebug(6)
      call secget(isect(9),9,isec9)
      call rdedx(e,lds(isect(9)),isec9,ifild)
      nat3 = nat*3
      nlen = nat3*nat3
      iof = lenrel(nw196(5))
      iofs = nw196(5) + lenint(nat*nt)
      i10 = iofs + 1
      i11 = i10 + nlen
      ioff = i11 + nx
      noc1 = na + 1
c
c     perturbed fock matrix at section 16 , m.o. basis
c     derivatives of overlap at section 14
c
      ibf = iochf(16)
      ibs = iochf(14)
      ltri = ikyp(ncoorb)
      length = lensec(ltri)
      if (odebug(6)) then
         write (iwr,6010)
         do 30 n = 1 , nat3
            call rdedx(qq(i11),ltri,ibf,ifockf)
            call rdedx(qq(ioff),ltri,ibs,ifockf)
            ibf = ibf + length
            ibs = ibs + length
            do 20 i = 1 , ncoorb
               ii = ikyp(i) - 1
c
c     perturbed eigenvalues ( used as check only)
c
               e1(i) = qq(i11+ii) - e(i)*qq(ioff+ii)
 20         continue
            write (iwr,6020) (e1(i),i=1,ncoorb)
 30      continue
      end if
      ibf = iochf(16)
c
c     perturbed density matrix at section 15
c
      ibd = iochf(15)
      do 90 n = 1 , nat3
         n10 = i10 - 1 + n
c
c     complete derivative of fock matrix (only elements
c     with two occupied orbitals are needed)
c
         call rdedx(qq(i11),ltri,ibf,ifockf)
c
c     perturbed density matrix
c
         call rdedx(qq(ioff),ltri,ibd,ifockf)
c
c     derivative lagrangian elements for two occupied orbitals
c
         do 50 i = 1 , na
            ii = iky(i) - 1
            do 40 j = 1 , i
               ij = ii + j
               qq(ioff+ij) = qq(ioff+ij)*(e(i)+e(j)) + qq(i11+ij)
     +                       + qq(i11+ij)
 40         continue
 50      continue
c
c     derivative lagrangian elements for one occupied and one virtual m.
c
         do 70 i = noc1 , ncoorb
            ii = iky(i) - 1
            do 60 j = 1 , na
               ij = ii + j
               qq(ioff+ij) = qq(ioff+ij)*e(j)
 60         continue
 70      continue
c
c
         ibf = ibf + length
         ibd = ibd + length
         ibs = iochf(14)
         do 80 m = 1 , nat3
c
c     derivative overlap matrix
c
            call rdedx(qq(i11),ltri,ibs,ifockf)
            ibs = ibs + length
c
c     take product with overlap derivatives
c
            qq(n10+(m-1)*nat3) = -tracep(qq(i11),qq(ioff),ncoorb)
 80      continue
 90   continue
      call rdedx(qq(1),nw196(5),ibl196(5),ifild)
      if (out) then
         call dr2sym(qq(i10),qq(i11),iqq(1),iqq(iof+1),nat,nat3,
     +               nshell)
         write (iwr,6030)
         call prnder(qq(i10),nat3,iwr)
      end if
      call secget(isect(60),60,isec46)
      call rdedx(qq(i11),nlen,isec46,ifild)
      call vadd(qq(i11),1,qq(i10),1,qq(i11),1,nlen)
      call wrt3(qq(i11),nlen,isec46,ifild)
      return
 6010 format (//5x,'perturbed eigenvalues'//)
 6020 format (//(5x,6f16.8))
 6030 format (//' contribution from derivative of lagrangian')
      end
_ENDIF
      subroutine ovlop(qq,iqq)
c
c    assemble overlap contribution to high-spin open-shell
c    scf second derivatives
c
c   term involving derivative of lagrangian
c   open shell case
c
      implicit REAL  (a-h,o-z)
      logical out
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
      common/bufb/e(maxorb),e1(maxorb)
      dimension qq(*),iqq(*)
      common/maxlen/maxq
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
INCLUDE(common/symtry)
INCLUDE(common/prnprn)
c
      out = odebug(6)
      call secget(isect(9),9,isec9)
      call rdedx(e,lds(isect(9)),isec9,ifild)
      nat3 = nat*3
      nlen = nat3*nat3
      iof = lenrel(nw196(5))
      iofs = nw196(5) + lenint(nat*nt)
      i10 = iofs + 1
      i11 = i10 + nlen
      ioff = i11 + nx
      ioff2 = ioff + nx
      ioff3 = ioff2 + nx
      ioff4 = ioff3 + nx
      ioff5 = ioff4 + nx
      ioff6 = ioff5 + nx
      ioff7 = ioff6 + nx
      if (maxq.lt.(ioff7+nx+510+iofs)) call caserr(' insufficient core')
      ntpls1 = nb + 1
c     ndpls1 = na + 1
c     noc1 = nocca + 1
c
c     perturbed fock matrix at section 16 , m.o. basis
c     derivatives of overlap at section 14
c
      ibf = iochf(16)
      ibs = iochf(14)
      ltri = ikyp(ncoorb)
      length = lensec(ltri)
      if (odebug(6)) then
         write (iwr,6010)
         do 30 n = 1 , nat3
            call rdedx(qq(i11),ltri,ibf,ifockf)
            call rdedx(qq(ioff),ltri,ibs,ifockf)
            ibf = ibf + length
            ibs = ibs + length
            do 20 i = 1 , ncoorb
               ii = ikyp(i) - 1
c
c     perturbed eigenvalues ( used as check only)
c
               e1(i) = qq(i11+ii) - e(i)*qq(ioff+ii)
 20         continue
            write (iwr,6020) (e1(i),i=1,ncoorb)
 30      continue
      end if
      ibf = iochf(16)
      ibss = iochf(14)
      ibd = iochf(15)
c  part of perturbed fock matrix as calculated by fd2 at section 16
c  overlap derivatives at section 14
c  perturbed density matrices at section 15
      call secget(isect(43),43,iblok)
      call rdedx(qq(ioff3),ltri,iblok,ifild)
c  read in 1/2k
      do 90 n = 1 , nat3
         n10 = i10 - 1 + n
         call rdedx(qq(nlen),ltri,ibf,ifockf)
         call rdedx(qq(ioff),ltri,ibd,ifockf)
         call rdedx(qq(ioff2),ltri,ibss,ifockf)
c  form dk and kd
         call mxmtri(qq(ioff4),qq(ioff),qq(ioff3),ltri,ncoorb)
         call mxmtri(qq(ioff5),qq(ioff3),qq(ioff),ltri,ncoorb)
c  form kfs and sfk
         call mxmftr(qq(ioff6),qq(ioff3),qq(ioff2),ltri,ncoorb,na,
     +  nb)
         call mxmftr(qq(ioff7),qq(ioff2),qq(ioff3),ltri,ncoorb,na,
     +  nb)
c  two occupied orbitals
         do 50 i = 1 , nb
            foci = 2.0d0
            if (i.gt.na) foci = 1.0d0
            ii = iky(i) - 1
            do 40 j = 1 , i
               focj = 2.0d0
               if (j.gt.na) focj = 1.0d0
               ij = ii + j
               qq(ioff+ij) = qq(ioff+ij)*(e(i)+e(j))
     +                       /2.0d0 - qq(ioff2+ij)*(foci*e(i)+focj*e(j))
     +                       /2.0d0 + (foci-focj)
     +                       *(qq(ioff4+ij)-qq(ioff5+ij))
     +                       /2.0d0 + (foci+focj)
     +                       *(qq(ioff6+ij)+qq(ioff7+ij))
     +                       /2.0d0 + qq(i11+ij)
 40         continue
 50      continue
c  one occupied and one virtual m.o.
         do 70 i = ntpls1 , ncoorb
            ii = iky(i) - 1
            do 60 j = 1 , nb
               focj = 2.0d0
               if (j.gt.na) focj = 1.0d0
               ij = ii + j
               qq(ioff+ij) = qq(ioff+ij)*e(j) - focj*qq(ioff4+ij)
 60         continue
 70      continue
         ibf = ibf + length
         ibd = ibd + length
         ibss = ibss + length
         ibsb = iochf(14)
         do 80 m = 1 , nat3
            call rdedx(qq(i11),ltri,ibsb,ifockf)
            ibsb = ibsb + length
c
c     take product with overlap derivatives
c
            qq(n10+(m-1)*nat3) = -tracep(qq(i11),qq(ioff),ncoorb)
 80      continue
 90   continue
      if (out) then
         call rdedx(qq(1),nw196(5),ibl196(5),ifild)
         call dr2sym(qq(i10),qq(i11),iqq(1),iqq(iof+1),nat,nat3,
     +               nshell)
         write (iwr,6030)
         call prnder(qq(i10),nat3,iwr)
      end if
      call secget(isect(60),60,isec46)
      call rdedx(qq(i11),nlen,isec46,ifild)
      call vadd(qq(i11),1,qq(i10),1,qq(i11),1,nlen)
      call wrt3(qq(i11),nlen,isec46,ifild)
      return
 6010 format (//5x,'perturbed eigenvalues'//)
 6020 format (//(5x,6f16.8))
 6030 format (//' contribution from derivative of lagrangian')
      end
      subroutine sgmatm(fock,p,nfok,ltri)
c
c     closed shell fock operator construction
c     vectorised version to produce
c     many fock operators simulataneously
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension p(*),fock(*)
      common/blkin/gg(510),mword
INCLUDE(common/mapper)
INCLUDE(common/atmblk)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
      logical ohf_exch
_ENDIF
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
c
_IFN1(iv)      iword = 1
_IFN1(iv)      call unpack(gg(num2e+1),lab816,labs,numlab)
_IF1(iv)      call upak8v(gg(num2e+1),i205)
c
_IF(ccpdft)
      hf_wght  = CD_HF_exchange_weight()
      ohf_exch = (.not.CD_active()).or.CD_HF_exchange()
_ENDIF
      do 40 iw = 1 , mword

_IF(ibm,vax)
         i = i205(iw)
         j = j205(iw)
         k = k205(iw)
         l = l205(iw)
_ELSEIF(littleendian)
         i = labs(iword+1)
         j = labs(iword  )
         k = labs(iword+3)
         l = labs(iword+2)
_ELSE
         i = labs(iword)
         j = labs(iword+1)
         k = labs(iword+2)
         l = labs(iword+3)
_ENDIF
         gik = gg(iw)
         g2 = gik + gik
         g4 = g2 + g2
         ikyi = iky(i)
         ikyj = iky(j)
         ikyk = iky(k)
         ik = ikyi + k
         il = ikyi + l
         ij = ikyi + j
         jk = ikyj + k
         jl = ikyj + l
         kl = ikyk + l
         ioff = 0
_IF1(ct)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
         do 20 n = 1 , nfok
            aij = g4*p(kl+ioff) + fock(ij+ioff)
            fock(kl+ioff) = g4*p(ij+ioff) + fock(kl+ioff)
            fock(ij+ioff) = aij
            ioff = ioff + ltri
 20      continue
_IF1()      call daxpy(nfok,g4,p(ij),ltri,fock(kl),ltri)
_IF1()      if(ij.ne.kl)call daxpy(nfok,g4,p(kl),ltri,fock(ij),ltri)
c... exchange
_IF(ccpdft)
         if (ohf_exch) then
            g2  = hf_wght*g2
            gik = hf_wght*gik
         else
            iword = iword+4
            goto 40
         endif
_ENDIF
         gil = gik
         if (i.eq.k .or. j.eq.l) gik = g2
         if (j.eq.k) gil = g2
         if (j.lt.k) then
            jk = ikyk + j
            if (j.lt.l) then
               jl = iky(l) + j
            end if
         end if
         ioff = 0
_IF1(ct)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
         do 30 n = 1 , nfok
            ajk = fock(jk+ioff) - gil*p(il+ioff)
            ail = fock(il+ioff) - gil*p(jk+ioff)
            aik = fock(ik+ioff) - gik*p(jl+ioff)
            fock(jl+ioff) = fock(jl+ioff) - gik*p(ik+ioff)
            fock(jk+ioff) = ajk
            fock(il+ioff) = ail
            fock(ik+ioff) = aik
            ioff = ioff + ltri
 30      continue
         iword = iword + 4
 40   continue
      return
      end
      subroutine chfeqs(eps,b,cc,wks1,wks2,alpha,aa,ndim,skipp)
      implicit REAL  (a-h,o-z)
c
c     simultaneous equations - small case
c
      logical skipp
      dimension skipp(100)
c
      dimension eps(ndim),b(ndim),cc(ndim),wks1(ndim),wks2(ndim),
     &    alpha(ndim,ndim),aa(ndim,ndim)
_IF(rpagrad)
INCLUDE(common/sizes)
INCLUDE(common/rpadcom)
INCLUDE(common/infoa)
_ENDIF
INCLUDE(common/cigrad)
INCLUDE(common/atmblk)
INCLUDE(common/prnprn)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/ii(340),jj(340)
      common/blkin/g(510),nword
c
      data zero,one/0.0d0,1.0d0/
c
c
      lenblk = lensec(mn)
c
c     rhs of equations input from scratchfile
c
_IF(rpagrad)
      if (orpagrad) then
         mnij  = nocca*nocca
         mnab  = nvirta*nvirta
         iblkb = iblks + 3*nat*(lensec(mnij)+lensec(mnab))
      else
         iblkb = iblks
      endif
_ELSE
      iblkb = iblks
_ENDIF
      iblku = iblkb + lenblk*np
      idev4 = nofile(1)
      iblk4 = jblk(1)
      if (oprn(12)) write (iwr,6010)
      if (oprn(13)) write (iwr,6020)
      ifail = 0
c
      do 30 i = 1 , mn
         do 20 j = 1 , mn
            alpha(j,i) = zero
 20      continue
 30   continue
      do 40 i = 1 , mn
         alpha(i,i) = one/eps(i)
 40   continue
c
c     read thru 2-electron integrals ( a-matrix )
c     file idev4 = nofile(1) = ed4 (default)
c     iblk4 =starting block
c
      call search(iblk4,idev4)
      call find(idev4)
 50   call get(g(1),nw)
      if (nw.gt.0) then
         if (nword.gt.0) then
c
c     use a block of integrals
c
            call find(idev4)
_IFN1(iv)            call unpack(g(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)            call upak4v(g(num2ep+1),ii)
            do 60 i = 1 , nword
_IFN1(iv)               lab1 = labs(i+i-1)
_IFN1(iv)               lab2 = labs(i+i)
_IF1(iv)               lab1 = ii(i)
_IF1(iv)               lab2 = jj(i)
               gg = g(i)
               alpha(lab1,lab2) = alpha(lab1,lab2) + gg
               if (.not.(lcpf .or. cicv .or. cicx .or. lab1.eq.lab2))
     +             then
                  alpha(lab2,lab1) = alpha(lab2,lab1) + gg
               end if
 60         continue
            go to 50
         end if
      end if
c
c     loop over the perturbations
c
      if (odebug(2)) write (iwr,6030)
      if (odebug(2)) call prsqm(alpha,mn,mn,mn,iwr)
      do 80 i = 1 , mn
         do 70 j = 1 , mn
            alpha(i,j) = alpha(i,j)*eps(i)
 70      continue
 80   continue
c
      do 110 ko = 1 , np
c     get rhs
c
         call rdedx(b,mn,iblkb,ifils)
c      write(iwr,978)(b(i),i=1,mn)
c978   format(' b in chfeqs = ',5f15.10)
         if (oprn(12)) write (iwr,6040) ko , (b(i),i=1,mn)
         iblkb = iblkb + lenblk
         do 90 i = 1 , mn
            cc(i) = 0.0d0
 90      continue
         if (odebug(2).and.skipp(ko)) write (iwr,6050) ko
         if (.not.(skipp(ko))) then
            do 100 i = 1 , mn
               b(i) = -b(i)*eps(i)
 100        continue
c
c    use nag routine to solve
c
            call f04atf(alpha,mn,b,mn,cc,aa,mn,wks1,wks2,ifail)
         end if
c
c    write solution onto scratchfile
c
         call wrt3(cc,mn,iblku,ifils)
         iblku = iblku + lenblk
         if (oprn(12) .or. oprn(13)) then
            write (iwr,6060) ko , (cc(i),i=1,mn)
         end if
 110  continue
      return
 6010 format (//1x,'print right-hand-side of chf equations')
 6020 format (//1x,'print solution to chf equations')
 6030 format (//1x,'a-matrix routine chfeqs')
 6040 format (//1x,'perturbation  ',i4//(5x,5f16.8))
 6050 format (/1x,'perturbation',i5,' omitted')
 6060 format (//1x,'solution  ',i4//(5x,5f16.8))
      end
      subroutine mxmtri(a,b,c,ltri,n)
c
c  produces lower triangle of the product matrix a=bc
c  where b and c are symmetric matrices input as lower triangles
c  n is the dimension of the square matrices,
c  ltri is number of elements in lower triangle.
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
      dimension a(ltri),b(ltri),c(ltri)
      do 20 i = 1 , ltri
         a(i) = 0.0d0
 20   continue
      do 50 i = 1 , n
         ii = iky(i)
         do 40 k = 1 , n
            ik = ii + k
            if (k.gt.i) ik = iky(k) + i
            bik = b(ik)
            if (bik.ne.0.0d0) then
               kk = iky(k)
               do 30 j = 1 , i
                  jk = kk + j
                  if (j.gt.k) jk = iky(j) + k
                  a(ii+j) = a(ii+j) + bik*c(jk)
 30            continue
            end if
 40      continue
 50   continue
      return
      end
      subroutine mxmftr(a,b,c,ltri,n,ndoc,ntot)
c
c  produces lower triangle of the product matrix a=bfc
c  where b and c are symmetric matrices input as lower triangles
c  and f is the occupation number of the kth orbital (f=0,1,2)
c  n is the dimension of the square matrices,
c  ltri is number of elements in lower triangle.
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
      dimension a(ltri),b(ltri),c(ltri)
      do 20 i = 1 , ltri
         a(i) = 0.0d0
 20   continue
      do 50 i = 1 , n
         ii = iky(i)
         do 40 k = 1 , ntot
            fock = 2.0d0
            if (k.gt.ndoc) fock = 1.0d0
            ik = ii + k
            if (k.gt.i) ik = iky(k) + i
            bfik = b(ik)*fock
            if (bfik.ne.0.0d0) then
               kk = iky(k)
               do 30 j = 1 , i
                  jk = kk + j
                  if (j.gt.k) jk = iky(j) + k
                  a(ii+j) = a(ii+j) + bfik*c(jk)
 30            continue
            end if
 40      continue
 50   continue
      return
      end
      subroutine chfcls(a,maxa)
c
c   sorts out a-matrix ( hessian ) for closed shell chf
c   ------------------------------------------------------
c
      implicit REAL  (a-h,o-z)
      dimension a(*)
c
INCLUDE(common/sizes)
INCLUDE(common/cigrad)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/prnprn)
INCLUDE(common/atmblk)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/blkin/g(510),nword
      character*10 charwall
c
_IF(ccpdft)
      hf_wght = CD_HF_exchange_weight()
_ENDIF
      call search(jblk(1),nofile(1))
c
c     work out number of passes
c     a matrix is mn*(mn+1)/2 ; core available is maxa
c
_IFN1(iv)      call setsto(1360,0,labs)
_IF1(iv)      call setsto(1360,0,i205)
      if (.not.lcpf .and. .not.cicv .and. (.not.cicx)) mnnr = mn
      nst = 0
      nmin = 0
      nfin = mnnr
      do 20 nn = 1 , mnnr
         last = nn*(nn+1)/2
         if (last.gt.maxa) then
            nfin = nn - 1
            go to 30
         end if
 20   continue
 30   call vclr(a,1,maxa)
c
c     loop over the transformed two-electron integrals
c     which are input from ed6 ( default)
c
      do 60 ifile = 1 , mmfile
         mblkk = kblk(ifile)
         idevm = nufile(ifile)
c        lblkm = nblk(ifile)
c
c
         call search(mblkk,idevm)
 40      call find(idevm)
c
c     read block of integrals into /blkin/
c
         call get(g(1),nw)
         if (nword.gt.0) then
            if (nw.gt.0) then
c
c     loop over integrals in a block
c
_IFN1(iv)               call unpack(g(num2e+1),lab816,labs,numlab)
_IF1(iv)               call upak8v(g(num2e+1),i205)
               do 50 kk = 1 , nword
c
c     unpack the labels
c
_IFN1(iv)                  kk2 = kk + kk + kk + kk
_IF(ibm,vax)
                  i = i205(kk)
                  j = j205(kk)
                  k = k205(kk)
                  l = l205(kk)
_ELSEIF(littleendian)
                  i = labs(kk2-2)
                  j = labs(kk2-3)
                  k = labs(kk2  )
                  l = labs(kk2-1)
_ELSE
                  i = labs(kk2-3)
                  j = labs(kk2-2)
                  k = labs(kk2-1)
                  l = labs(kk2)
_ENDIF
                  gg = g(kk)
                  if (i.gt.nocca) then
                     if (l.le.nocca) then
                        if (j.le.nocca) then
                           if (k.gt.nocca) then
c
c     type (xo/xo)
c
                              naa = (i-nocca-1)*nocca + j
                              nbb = (k-nocca-1)*nocca + l
                              if (naa.lt.nbb) then
                                 nswop = naa
                                 naa = nbb
                                 nbb = nswop
                              end if
                              if (naa.gt.nst .and. naa.le.nfin) then
                                 ntri = naa*(naa-1)/2 + nbb - nmin
                                 a(ntri) = a(ntri) + 4.0d0*gg
                              end if
                              naa = (i-nocca-1)*nocca + l
                              nbb = (k-nocca-1)*nocca + j
                              if (naa.lt.nbb) then
                                 nswop = naa
                                 naa = nbb
                                 nbb = nswop
                              end if
                              if (naa.gt.nst .and. naa.le.nfin) then
                                 ntri = naa*(naa-1)/2 + nbb - nmin
_IF(ccpdft)
                                 a(ntri) = a(ntri) - gg*hf_wght
_ELSE
                                 a(ntri) = a(ntri) - gg
_ENDIF
                              end if
                           end if
                        else if (k.le.nocca) then
c
c     type (xx/oo)
c
                           naa = (i-nocca-1)*nocca + k
                           nbb = (j-nocca-1)*nocca + l
                           if (naa.lt.nbb) then
                              nswop = naa
                              naa = nbb
                              nbb = nswop
                           end if
c
c     only that part of triangle between a(nst+1,1) and a(nfin,nfin)
c     is constructed in this pass
c
                           if (naa.gt.nst .and. naa.le.nfin) then
                              ntri = naa*(naa-1)/2 + nbb - nmin
_IF(ccpdft)
                              a(ntri) = a(ntri) - gg*hf_wght
_ELSE
                              a(ntri) = a(ntri) - gg
_ENDIF
                           end if
                           if (i.ne.j .and. k.ne.l) then
                              naa = (i-nocca-1)*nocca + l
                              nbb = (j-nocca-1)*nocca + k
                              if (naa.lt.nbb) then
                                 nswop = naa
                                 naa = nbb
                                 nbb = nswop
                              end if
                              if (naa.gt.nst .and. naa.le.nfin) then
                                 ntri = naa*(naa-1)/2 + nbb - nmin
_IF(ccpdft)
                                 a(ntri) = a(ntri) - gg*hf_wght
_ELSE
                                 a(ntri) = a(ntri) - gg
_ENDIF
                              end if
                           end if
                        end if
                     end if
                  end if
c
 50            continue
               go to 40
            end if
         end if
 60   continue
      call wamat(a,mnnr,nofile(1),nst,nfin,odebug(2),iwr)
      if (nfin.eq.mnnr) then
c
         nword = 0
         mblk(1) = iposun(nofile(1)) - 1
         if (nprint.ne.-5) then
            dum = cpulft(1)
            write (iwr,6010) dum ,charwall()
         end if
         return
      else
         nst = nfin
         nfin = mnnr
         nmin = nst*(nst+1)/2
         nstp1 = nst + 1
         do 70 nn = nstp1 , mnnr
            last = nn*(nn+1)/2 - nmin
            if (last.gt.maxa) then
               nfin = nn - 1
               go to 30
            end if
 70      continue
      end if
      go to 30
 6010 format (/1x,'construction of a-matrix complete at ',f8.2,
     +        ' seconds',a10,' wall'/)
      end
_EXTRACT(chfgrs,hp800)
      subroutine chfgrs(eps,mapnr,eta,zeta,a,iblok,iblok2,maxa)
c
c     a sorting routine for hessian for general scf chf equations
c
      implicit REAL  (a-h,o-z)
      dimension eta(*),zeta(nx,njk1),mapnr(*),a(*),eps(*)
c
INCLUDE(common/sizes)
INCLUDE(common/cigrad)
INCLUDE(common/symtry)
INCLUDE(common/ghfblk)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/mapper)
INCLUDE(common/prnprn)
INCLUDE(common/atmblk)
      common/maxlen/maxq
      common/blkin/g(510),nword
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/mpshl/ns(maxorb)
      character*10 charwall
      data prec,fattor/1.0d-9,2.0d0/
      data two, one /2.0d0, 1.0d0 /
      data half / 0.5d0 /
      ioff(i) = i*(i-1)/2
c
c     lennew = iky(nsa4+1)
c
      if (.not.lcpf .and. .not.cicv .and. (.not.cicx)) mnnr = mn
_IFN1(iv)      do 20 iiii = 1 , 1360
_IFN1(iv)         labs(iiii) = 0
_IFN1(iv) 20   continue
_IF1(iv)      call setsto(1360,0,i205)
c     lenblk = lensec(mn)
      call rdedx(eta,nx,iblok,ifils)
      call rdedx(zeta,nx*njk1,iblok2,ifils)
c
c      integrals are read from ed6 (nufile(1))
c      result is output on ed4 (nofile(1))
c      only integrals of type (xo/xo) and (xx/oo) are
c      required though more can be present on ed6.
c
c      input integrals in canonical order
c      lower triangle of a-matrix is output
c
c      several passes through integral file allowed
c
      call search(jblk(1),nofile(1))
c
c     work out number of passes
c     a matrix is mn*(mn+1)/2 ; core available is maxa
c
      npass = (mnnr*(mnnr+1)/2)/maxa + 1
      if(odebug(39)) then
       write(iwr,6020) npass
       write(iwr,6040) maxa, mnnr
      endif
      nst = 0
      nmina = 1
      nmin = 0
      nfin = mnnr
      nfinx = mnnr*(mnnr+1)/2
      do 30 nn = 1 , mnnr
         last = nn*(nn+1)/2
         if (last.gt.maxa) then
            nfin = nn - 1
            nfinx = nfin*(nfin+1)/2
            write(iwr,*) ' sortj : number of passes gt 1 '
            go to 40
         end if
 30   continue
 40   call vclr(a,1,maxa)
c
c     loop over the transformed two-electron integrals
c     which are input from ed6 ( default)
c
      do 70 ifile = 1 , mmfile
         mblkk = kblk(ifile)
         idevm = nufile(ifile)
c        lblkm = nblk(ifile)
c
         call search(mblkk,idevm)
 50      call find(idevm)
c
c     read block of integrals into /blkin/
c
         call get(g(1),nw)
         if (nword.gt.0) then
            if (nw.gt.0) then
c
c     loop over integrals in a block
c
_IFN1(iv)               call unpack(g(num2e+1),lab816,labs,numlab)
_IF1(iv)               call upak8v(g(num2e+1),i205)
               do 60 kk = 1 , nword
c
c     unpack the labels
c
_IFN1(iv)                  kk2 = kk + kk + kk + kk

_IF(ibm,vax)
                  i = i205(kk)
                  j = j205(kk)
                  k = k205(kk)
                  l = l205(kk)
_ELSEIF(littleendian)
                  i = labs(kk2-2)
                  j = labs(kk2-3)
                  k = labs(kk2  )
                  l = labs(kk2-1)
_ELSE
                  i = labs(kk2-3)
                  j = labs(kk2-2)
                  k = labs(kk2-1)
                  l = labs(kk2)
_ENDIF
                  gg = -g(kk)
                  ij = ioff(i) + j
                  kl = ioff(k) + l
                  ik = ioff(i) + k
                  jl = ioff(j) + l
                  if (l.gt.j) jl = ioff(l) + j
                  il = ioff(i) + l
                  jk = ioff(j) + k
                  if (k.gt.j) jk = ioff(k) + j
c
                  if (ijkltp(i,j,k,l).lt.4) go to 60
                  if (i.eq.j) gg = gg*half
                  if (k.eq.l) gg = gg*half
                  if (i.eq.k .and. j.eq.l) gg = gg*half
c
                  if (mapnr(ij).gt.0 .and. mapnr(kl).gt.0) then
                     ntri = ioff(mapnr(ij)) + mapnr(kl)
                     if (ntri.gt.nmin .and. ntri.le.nfinx) then
                        ntri = ntri - nmin
                        a(ntri) = a(ntri) + two*aijkl(i,j,k,l,ns,erga)
     +                            *gg
                     end if
                  end if
c
                  if (mapnr(ik).gt.0 .and. mapnr(jl).gt.0) then
                     ntri = ioff(mapnr(ik)) + mapnr(jl)
                     if (ntri.gt.nmin .and. ntri.le.nfinx) then
                        ntri = ntri - nmin
                        jsw = j
                        lsw = l
                        if (j.lt.l) then
                           jsw = l
                           lsw = j
                        end if
                        a(ntri) = a(ntri) + aijkl(i,k,jsw,lsw,ns,ergb)
     +                            *gg
                     end if
                  end if
c
                  if (mapnr(il).gt.0 .and. mapnr(jk).gt.0) then
                     ntri = ioff(mapnr(il)) + mapnr(jk)
                     if (mapnr(il).lt.mapnr(jk)) ntri = ioff(mapnr(jk))
     +                   + mapnr(il)
                     if (ntri.gt.nmin .and. ntri.le.nfinx) then
                        ntri = ntri - nmin
                        jsw = j
                        ksw = k
                        if (j.lt.k) then
                           jsw = k
                           ksw = j
                        end if
                        a(ntri) = a(ntri) + aijkl(i,l,jsw,ksw,ns,ergb)
     +                            *gg
                     end if
                  end if
c
 60            continue
               go to 50
            end if
         end if
 70   continue
c
      do 80 ixj = nmina , nfin
         ixx = ixj*(ixj+1)/2 - nmin
         a(ixx) = a(ixx)*two
 80   continue
      do 120 ix = 1 , nsa4
         do 110 jx = 1 , ix
            ijx = ioff(ix) + jx
            if (mapnr(ijx).ne.0) then
               do 100 kx = 1 , ix
                  lmax = kx
                  if (ix.eq.kx) lmax = jx
                  do 90 lx = 1 , lmax
                     klx = ioff(kx) + lx
                     if (mapnr(klx).ne.0) then
                        ntri = ioff(mapnr(ijx)) + mapnr(klx)
                        if (ntri.gt.nmin .and. ntri.le.nfinx) then
                           ntri = ntri - nmin
                           ikx = ioff(ix) + kx
                           ilx = ioff(ix) + lx
                           jlx = ioff(jx) + lx
                           jkx = ioff(jx) + kx
                           if (lx.gt.jx) jlx = ioff(lx) + jx
                           if (kx.gt.jx) jkx = ioff(kx) + jx
                           if (lx.eq.jx) a(ntri) = a(ntri)
     +                         - (eta(ikx)-zeta(ikx,ns(jx)))
                           if (jx.eq.kx) a(ntri) = a(ntri)
     +                         + (eta(ilx)-zeta(ilx,ns(jx)))
                           if (kx.eq.ix) a(ntri) = a(ntri)
     +                         - (eta(jlx)-zeta(jlx,ns(ix)))
                           if (lx.eq.ix) a(ntri) = a(ntri)
     +                         + (eta(jkx)-zeta(jkx,ns(ix)))
                        end if
                     end if
 90               continue
 100           continue
            end if
 110     continue
 120  continue
c
c
c    this sets up the array eps(mn) to hold the diagonal values of
c    a which are used to divide b in the solution of (1-a)u=b
c
      do 140 ixj = nmina , nfin
         ixx = ixj*(ixj+1)/2 - nmin
c     new partition of the a matrix into diagonal-off
c     diagonal components
         aixx = a(ixx)
         aaixx = dabs(aixx)
         ixi0 = ixx - ixj + 1
         ixi1 = ixx - 1
c    scan last row of a matrix and find largest absolute value
         aaizz = 0.d0
         do 130 ixi = ixi0 , ixi1
            aiyy = a(ixi)
            aaiyy = dabs(aiyy)
            if (aaiyy.gt.aaizz) then
               aaizz = aaiyy
            end if
 130     continue
         if (aaixx.lt.prec) then
            diago = 1.0d0
            eps(ixj) = one/diago
            a(ixx) = a(ixx) - diago
         else if (aaizz.lt.prec) then
            eps(ixj) = one/aixx
            a(ixx) = 0.d0
         else if (aaixx/aaizz.gt.fattor) then
            eps(ixj) = one/aixx
            a(ixx) = 0.d0
         else
            diago = aixx*aaizz*fattor
            eps(ixj) = one/diago
            a(ixx) = a(ixx) - diago
         end if
 140  continue
      call wamat(a,mnnr,nofile(1),nst,nfin,odebug(2),iwr)
      if (nfin.eq.mnnr) then
c
         nword = 0
         mblk(1) = iposun(nofile(1)) - 1
         write (iwr,6010) cpulft(1) ,charwall()
         return
      else
         nst = nfin
         nmina = nfin + 1
         nfin = mnnr
         nfinx = mnnr*(mnnr+1)/2
         nmin = nst*(nst+1)/2
         nstp1 = nst + 1
         do 150 nn = nstp1 , mnnr
            last = nn*(nn+1)/2 - nmin
            if (last.gt.maxa) then
               nfin = nn - 1
               nfinx = nfin*(nfin+1)/2
               go to 160
            end if
 150     continue
 160     write(iwr,6030)cpulft(1) ,charwall()
         go to 40
      end if
 6010 format (/1x,'construction of a-matrix complete at',
     +  f8.2,' seconds',a10,' wall'/)
 6020 format (/1x,'rough estimate of number of passes ',i3)
 6030 format (/1x,'commence next pass at ',f8.2,' seconds',a10,' wall')
 6040 format (1x,'maxa,mnnr = ' , 2i10)
      end
_ENDEXTRACT
      subroutine chfops(akm,maxa)
      implicit REAL  (a-h,o-z)
      dimension akm(*)
INCLUDE(common/sizes)
c
c     hessian sorting routine for open shell chf
c
_IFN1(iv)      common/craypk/labs(1360)
_IFN1(iv)      common/small/labout(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
_IF1(iv)      common/small/labij(340),labkl(340)
      common/blkin/g(510),nword
      common/out/a(510),nn
c
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
      common/maxlen/maxq
INCLUDE(common/mapper)
INCLUDE(common/atmblk)
c
      data m0,m1/0,1/
      data m101,m102,m103,m104,m105,m106,m107,m108,m109,m110,m111,m112/
     $21,22,23,24,25,26,27,28,29,30,31,32/
      data m131,m132,m133,m134,m135,m136,m137,m138,m139,m140,m141,m142/
     $41,42,43,44,45,46,47,48,49,50,51,52/
      data m151,m152,m153,m154,m155,m156,m157,m158,m159,m160,m161,m162/
     $61,62,63,64,65,66,67,68,69,70,71,72/
      data m113/80/
      data fd,fs,fv/2.0d0,1.0d0,0.0d0/
c
      ind(i,j) = iky(max(i,j)) + min(i,j)
c
c     read the k-matrix
c
      call secget(isect(43),43,iblok)
      call rdedx(akm(1),lds(isect(43)),iblok,ifild)
c
c      map to active orbitals only
c
      call actmot(akm,nsa4,mapie,iky)
c
c      routine sorto sorts the two-electron integrals
c      the integrals are multiplied
c      by the required weighting factor and the indices ii
c      and jj indicate the array elements to which each
c      integral contributes  ---- i.e. sets up a small
c      formula tape.
c      open shell case. ii is i,j. jj is k,l. i.e. ordering of
c      indices reversed from that in p. saxe's paper.
c      entire matrix is output, not lower triangle.
c      sorter is for real perturbations
c
_IFN1(iv)      do 20 iiii = 1 , 1360
_IFN1(iv)         labout(iiii) = 0
_IFN1(iv) 20   continue
_IFN1(iv)      call setsto(1360,0,labs)
_IF1(iv)      call izero(680,labij,1)
_IF1(iv)      call setsto(1360,0,i205)
      fsdvd = -1.0d0
      fvdvd = -1.0d0
      fvsvd = -1.0d0
      fsdsd = -(fs+fd-1.0d0)/2.0d0
      fvdsd = -(fv+fd-1.0d0)/2.0d0
      fvssd = -(fv+fs-1.0d0)/2.0d0
      fsdvs = -(3.0d0-fs-fd)/2.0d0
      fvdvs = -(3.0d0-fv-fd)/2.0d0
      fvsvs = -(3.0d0-fv-fs)/2.0d0
c
c     integrals are read in from the transformed mainfile (ed6)
c     and are written out to secondary mainfile (ed4 = idev4)
c
      idev4 = ifils
      iblk4 = iblks
      call search(iblk4,idev4)
      nsoc = noccb - nocca
      nvirta = nsa4 - noccb
      ipos = m0
c
c     read through integral file
c
      do 470 ifile = 1 , mmfile
         mblkk = kblk(ifile)
         idevm = nufile(ifile)
         lblkm = nblk(ifile)
         call search(mblkk,idevm)
         do 460 ib = mblkk , lblkm
            call find(idevm)
            call get(g(1),nw)
            if (nw.le.m0) go to 470
_IFN1(iv)            call unpack(g(num2e+1),lab816,labs,numlab)
_IF1(iv)            call upak8v(g(num2e+1),i205)
            do 450 kk = 1 , nword
c
c     unpack integral labels
c
_IFN1(iv)               kk2 = kk + kk + kk + kk
_IF(ibm,vax)
               i = i205(kk)
               j = j205(kk)
               k = k205(kk)
               l = l205(kk)
_ELSEIF(littleendian)
               i = labs(kk2-2)
               j = labs(kk2-3)
               k = labs(kk2  )
               l = labs(kk2-1)
_ELSE
               i = labs(kk2-3)
               j = labs(kk2-2)
               k = labs(kk2-1)
               l = labs(kk2)
_ENDIF
               gg = g(kk)
               if (k.gt.noccb) then
                  if (l.gt.noccb) go to 450
                  if (j.gt.noccb) go to 450
                  if (l.le.nocca) then
                     if (j.gt.nocca) go to 240
c
c     type (vd/vd)
c
                     naa = (i-nocca-m1)*nocca + j
                     nbb = (k-nocca-m1)*nocca + l
                     ipos = ipos + m1
                     label = m103
                     xx = 4.0d0
                     if (i.eq.k .or. j.eq.l) xx = 4.0d0 + fvdvd
                     a(ipos) = xx*gg
                     if (i.eq.k) a(ipos) = a(ipos) + 2.0d0*akm(ind(j,l))
                     if (j.eq.l) a(ipos) = a(ipos) + 2.0d0*akm(ind(i,k))
_IF(ibm,vax)
                     labij(ipos) = naa
                     labkl(ipos) = nbb
_ELSE
                     labout(ipos+ipos-1) = naa
                     labout(ipos+ipos) = nbb
_ENDIF
                     if (ipos.ge.num2e) go to 400
                     go to 90
                  else
                     if (j.le.nocca) go to 240
c
c     type (vs/vs)
c
                     naa = nvirta*nocca + (i-nsoc-m1)*nsoc + j - nocca
                     nbb = nvirta*nocca + (k-nsoc-m1)*nsoc + l - nocca
                     ipos = ipos + m1
                     label = m109
                     xx = 2.0d0
                     if (i.eq.k .or. j.eq.l) xx = 2.0d0 + fvsvs
                     a(ipos) = xx*gg
                     if (i.eq.k) a(ipos) = a(ipos) + akm(ind(j,l))
                     if (j.eq.l) a(ipos) = a(ipos) + akm(ind(i,k))
_IF(ibm,vax)
                     labij(ipos) = naa
                     labkl(ipos) = nbb
_ELSE
                     labout(ipos+ipos-1) = naa
                     labout(ipos+ipos) = nbb
_ENDIF 
               if (ipos.ge.num2e) go to 400
                     go to 280
                  end if
               else if (k.le.nocca) then
                  if (j.le.nocca) go to 450
                  if (i.le.noccb) then
c
c     type (ss/dd)
c
                     naa = (i-nocca-m1)*nocca + k
                     nbb = (j-nocca-m1)*nocca + l
                     ipos = ipos + m1
                     label = m104
                     a(ipos) = fsdsd*gg
_IF(ibm,vax)
                     labij(ipos) = naa
                     labkl(ipos) = nbb
_ELSE
                     labout(ipos+ipos-1) = naa
                     labout(ipos+ipos) = nbb
_ENDIF
                     if (ipos.ge.num2e) go to 400
                     go to 120
                  else if (j.le.noccb) then
c
c     type (vs/dd)
c
                     naa = (i-nocca-m1)*nocca + k
                     nbb = (j-nocca-m1)*nocca + l
                     ipos = ipos + m1
                     label = m106
                     a(ipos) = fvdsd*gg
_IF(ibm,vax)
                     labij(ipos) = naa
                     labkl(ipos) = nbb
_ELSE
                     labout(ipos+ipos-1) = naa
                     labout(ipos+ipos) = nbb
_ENDIF
                     if (ipos.ge.num2e) go to 400
                     go to 180
                  else
c
c     type (vv/dd)
c
                     naa = (i-nocca-m1)*nocca + k
                     nbb = (j-nocca-m1)*nocca + l
                     ipos = ipos + m1
                     label = m110
                     a(ipos) = fvdvd*gg
_IF(ibm,vax)
                     labij(ipos) = naa
                     labkl(ipos) = nbb
_ELSE
                     labout(ipos+ipos-1) = naa
                     labout(ipos+ipos) = nbb
_ENDIF
                     if (ipos.ge.num2e) go to 400
                     go to 310
                  end if
               else if (l.le.nocca) then
                  if (i.le.noccb) then
                     if (j.gt.nocca) go to 450
c
c     type (sd/sd)
c
                     naa = (i-nocca-m1)*nocca + j
                     nbb = (k-nocca-m1)*nocca + l
                     ipos = ipos + m1
                     label = m101
                     xx = 2.0d0
                     if (i.eq.k .or. j.eq.l) xx = 2.0d0 + fsdsd
                     a(ipos) = xx*gg
                     if (i.eq.k) a(ipos) = a(ipos) + akm(ind(j,l))
                     if (j.eq.l) a(ipos) = a(ipos) + akm(ind(i,k))
_IF(ibm,vax)
                     labij(ipos) = naa
                     labkl(ipos) = nbb
_ELSE
                     labout(ipos+ipos-1) = naa
                     labout(ipos+ipos) = nbb
_ENDIF
                     if (ipos.ge.num2e) go to 400
                  else if (j.le.noccb) then
                     if (j.le.nocca) then
c
c     type (vd/sd)
c
                        naa = (i-nocca-m1)*nocca + j
                        nbb = (k-nocca-m1)*nocca + l
                        ipos = ipos + m1
                        label = m102
                        xx = 2.0d0
                        if (j.eq.l) xx = 2.0d0 + fvdsd
                        a(ipos) = xx*gg
                        if (j.eq.l) a(ipos) = a(ipos) + akm(ind(i,k))
_IFN1(iv)                        labout(ipos+ipos-1) = naa
_IFN1(iv)                        labout(ipos+ipos) = nbb
_IF1(iv)                     labij(ipos) = naa
_IF1(iv)                     labkl(ipos) = nbb
                        if (ipos.ge.num2e) go to 400
                        go to 60
                     else
c
c     type (vs/sd)
c
                        naa = nvirta*nocca + (i-nsoc-m1)*nsoc + 
     +                        j - nocca
                        nbb = (k-nocca-m1)*nocca + l
                        ipos = ipos + m1
                        label = m107
                        xx = 2.0d0
                        if (j.eq.k) xx = 2.0d0 + fvssd
                        a(ipos) = xx*gg
                        if (j.eq.k) a(ipos) = a(ipos) + akm(ind(i,l))
_IFN1(iv)                        labout(ipos+ipos-1) = naa
_IFN1(iv)                        labout(ipos+ipos) = nbb
_IF1(iv)                     labij(ipos) = naa
_IF1(iv)                     labkl(ipos) = nbb
                        if (ipos.ge.num2e) go to 400
                        go to 210
                     end if
                  else
c
c     type (vv/sd)
c
                     naa = nocca*nvirta + (i-nsoc-m1)*nsoc + k - nocca
                     nbb = (j-nocca-m1)*nocca + l
                     ipos = ipos + m1
                     label = m111
                     a(ipos) = fvsvd*gg
_IFN1(iv)                     labout(ipos+ipos-1) = naa
_IFN1(iv)                     labout(ipos+ipos) = nbb
_IF1(iv)                     labij(ipos) = naa
_IF1(iv)                     labkl(ipos) = nbb
                     if (ipos.ge.num2e) go to 400
                     go to 340
                  end if
               else
                  if (i.le.noccb) go to 450
                  if (j.le.noccb) then
                     if (j.gt.nocca) go to 450
c
c     type (vd/ss)
c
                     naa = nvirta*nocca + (i-nsoc-m1)*nsoc + k - nocca
                     nbb = (l-nocca-m1)*nocca + j
                     ipos = ipos + m1
                     label = m105
                     a(ipos) = fvssd*gg
_IFN1(iv)                     labout(ipos+ipos-1) = naa
_IFN1(iv)                     labout(ipos+ipos) = nbb
_IF1(iv)                     labij(ipos) = naa
_IF1(iv)                     labkl(ipos) = nbb
                     if (ipos.ge.num2e) go to 400
                     go to 150
                  else
c
c     type (vv/ss)
c
                     naa = nocca*nvirta + (i-nsoc-m1)*nsoc + k - nocca
                     nbb = nvirta*nocca + (j-nsoc-m1)*nsoc + l - nocca
                     ipos = ipos + m1
                     label = m112
                     a(ipos) = fvsvs*gg
_IFN1(iv)                     labout(ipos+ipos-1) = naa
_IFN1(iv)                     labout(ipos+ipos) = nbb
_IF1(iv)                     labij(ipos) = naa
_IF1(iv)                     labkl(ipos) = nbb
                     if (ipos.ge.num2e) go to 400
                     go to 370
                  end if
               end if
 30            if (naa.eq.nbb) go to 450
               ipos = ipos + m1
               label = m131
               a(ipos) = xx*gg
               if (i.eq.k) a(ipos) = a(ipos) + akm(ind(j,l))
               if (j.eq.l) a(ipos) = a(ipos) + akm(ind(i,k))
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 40            if (i.eq.k .or. j.eq.l) go to 450
               naa = (i-nocca-m1)*nocca + l
               nbb = (k-nocca-m1)*nocca + j
               ipos = ipos + m1
               label = m151
               a(ipos) = fsdsd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 50            ipos = ipos + m1
               label = m113
               a(ipos) = fsdsd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 60            ipos = ipos + m1
               label = m132
               xx = 4.0d0
               if (j.eq.l) xx = 4.0d0 + fsdvd
               a(ipos) = xx*gg
               if (j.eq.l) a(ipos) = a(ipos) + 2.0d0*akm(ind(k,i))
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 70            if (j.eq.l) go to 450
               naa = (i-nocca-m1)*nocca + l
               nbb = (k-nocca-m1)*nocca + j
               ipos = ipos + m1
               label = m152
               a(ipos) = fvdsd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 80            ipos = ipos + m1
               label = m113
               a(ipos) = fsdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 90            if (naa.eq.nbb) go to 450
               ipos = ipos + 1
               label = m133
               a(ipos) = xx*gg
               if (i.eq.k) a(ipos) = a(ipos) + 2.0d0*akm(ind(j,l))
               if (j.eq.l) a(ipos) = a(ipos) + 2.0d0*akm(ind(i,k))
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 100           if (i.eq.k .or. j.eq.l) go to 450
               naa = (i-nocca-m1)*nocca + l
               nbb = (k-nocca-m1)*nocca + j
               ipos = ipos + m1
               label = m153
               a(ipos) = fvdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 110           ipos = ipos + m1
               label = m113
               a(ipos) = fvdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 120           if (naa.eq.nbb) go to 450
               ipos = ipos + m1
               label = m134
               a(ipos) = fsdsd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 130           if (i.eq.j .or. k.eq.l) go to 450
               naa = (i-nocca-m1)*nocca + l
               nbb = (j-nocca-m1)*nocca + k
               ipos = ipos + m1
               label = m154
               a(ipos) = fsdsd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 140           ipos = ipos + 1
               label = m113
               a(ipos) = fsdsd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 150           ipos = ipos + 1
               label = m135
               a(ipos) = fsdvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 160           if (k.eq.l) go to 450
               naa = nvirta*nocca + (i-nsoc-m1)*nsoc + l - nocca
               nbb = (k-nocca-m1)*nocca + j
               ipos = ipos + m1
               label = m155
               a(ipos) = fvssd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 170           ipos = ipos + m1
               label = m113
               a(ipos) = fsdvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 180           ipos = ipos + m1
               label = m136
               a(ipos) = fsdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 190           if (k.eq.l) go to 450
               naa = (i-nocca-m1)*nocca + l
               nbb = (j-nocca-m1)*nocca + k
               ipos = ipos + m1
               label = m156
               a(ipos) = fvdsd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 200           ipos = ipos + m1
               label = m113
               a(ipos) = fsdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 210           ipos = ipos + 1
               label = m137
               if (j.eq.k) xx = 2.0d0 + fsdvs
               a(ipos) = xx*gg
               if (j.eq.k) a(ipos) = a(ipos) + akm(ind(l,i))
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 220           if (j.eq.k) go to 450
               naa = nvirta*nocca + (i-nsoc-m1)*nsoc + k - nocca
               nbb = (j-nocca-m1)*nocca + l
               ipos = ipos + m1
               label = m157
               a(ipos) = fvssd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 230           ipos = ipos + m1
               label = m113
               a(ipos) = fsdvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
c
c     type (vs/vd) and (vd/vs)
c
 240           naa = nvirta*nocca + (i-nsoc-m1)*nsoc + j - nocca
               nbb = (k-nocca-m1)*nocca + l
               if (j.lt.l) naa = nvirta*nocca + (k-nsoc-m1)*nsoc + l -
     +                          nocca
               if (j.lt.l) nbb = (i-nocca-m1)*nocca + j
               ipos = ipos + m1
               label = m108
               xx = 4.0d0
               if (i.eq.k) xx = 4.0d0 + fvsvd
               a(ipos) = xx*gg
               if (i.eq.k) a(ipos) = a(ipos) + 2.0d0*akm(ind(j,l))
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 250           ipos = ipos + m1
               label = m138
               xx = 2.0d0
               if (i.eq.k) xx = 2.0d0 + fvdvs
               a(ipos) = xx*gg
               if (i.eq.k) a(ipos) = a(ipos) + akm(ind(l,j))
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 260           if (i.eq.k) go to 450
               naa = nvirta*nocca + (k-nsoc-m1)*nsoc + j - nocca
               nbb = (i-nocca-m1)*nocca + l
               if (j.lt.l) naa = nvirta*nocca + (i-nsoc-m1)*nsoc + l -
     +                          nocca
               if (j.lt.l) nbb = (k-nocca-m1)*nocca + j
               ipos = ipos + m1
               label = m158
               a(ipos) = fvsvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 270           ipos = ipos + m1
               label = m113
               a(ipos) = gg*fvdvs
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 280           if (naa.eq.nbb) go to 450
               label = m139
               ipos = ipos + m1
               a(ipos) = xx*gg
               if (i.eq.k) a(ipos) = a(ipos) + akm(ind(j,l))
               if (j.eq.l) a(ipos) = a(ipos) + akm(ind(i,k))
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 290           if (i.eq.k .or. j.eq.l) go to 450
               naa = nvirta*nocca + (i-nsoc-m1)*nsoc + l - nocca
               nbb = nvirta*nocca + (k-nsoc-m1)*nsoc + j - nocca
               ipos = ipos + m1
               label = m159
               a(ipos) = fvsvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 300           ipos = ipos + m1
               label = m113
               a(ipos) = fvsvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 310           if (naa.eq.nbb) go to 450
               ipos = ipos + m1
               label = m140
               a(ipos) = fvdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 320           if (i.eq.j .or. k.eq.l) go to 450
               naa = (i-nocca-m1)*nocca + l
               nbb = (j-nocca-m1)*nocca + k
               ipos = ipos + m1
               label = m160
               a(ipos) = fvdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 330           ipos = ipos + m1
               label = m113
               a(ipos) = fvdvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 340           ipos = ipos + m1
               label = m141
               a(ipos) = fvdvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 350           if (i.eq.j) go to 450
               naa = nvirta*nocca + (j-nsoc-m1)*nsoc + k - nocca
               nbb = (i-nocca-m1)*nocca + l
               ipos = ipos + m1
               label = m161
               a(ipos) = fvsvd*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 360           ipos = ipos + m1
               label = m113
               a(ipos) = fvdvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
               go to 450
 370           if (naa.eq.nbb) go to 450
               ipos = ipos + m1
               label = m142
               a(ipos) = fvsvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.ge.num2e) go to 400
 380           if (i.eq.j .or. k.eq.l) go to 450
               naa = nvirta*nocca + (i-nsoc-m1)*nsoc + l - nocca
               nbb = nvirta*nocca + (j-nsoc-m1)*nsoc + k - nocca
               ipos = ipos + m1
               label = m162
               a(ipos) = fvsvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = naa
_IFN1(iv)               labout(ipos+ipos) = nbb
_IF1(iv)               labij(ipos) = naa
_IF1(iv)               labkl(ipos) = nbb
               if (ipos.ge.num2e) go to 400
 390           ipos = ipos + m1
               label = m113
               a(ipos) = fvsvs*gg
_IFN1(iv)               labout(ipos+ipos-1) = nbb
_IFN1(iv)               labout(ipos+ipos) = naa
_IF1(iv)               labij(ipos) = nbb
_IF1(iv)               labkl(ipos) = naa
               if (ipos.lt.num2e) go to 450
c
c
 400           nn = num2e
_IFN1(iv)               call pack(a(num2ep+1),lab1632,labout,numlabp)
_IF1(iv)            call pak4v(labij,a(num2ep+1))
               call put(a,m511,idev4)
_IFN1(iv)               do 410 iiii = 1 , 680
_IFN1(iv)                  labout(iiii) = 0
_IFN1(iv) 410           continue
_IF1(iv)      call izero(680,labij,1)
               ipos = m0
               iblk4 = iblk4 + m1
               label1 = label/20
               label2 = label - 20*label1
               go to (420,430,440,450) , label1
 420           go to (30,60,90,120,150,180,210,250,280,310,340,370) ,
     +                label2
 430           go to (40,70,100,130,160,190,220,260,290,320,350,380) ,
     +                label2
 440           go to (50,80,110,140,170,200,230,270,300,330,360,390) ,
     +                label2
 450        continue
 460     continue
 470  continue
c
c     write out block
c
      nn = ipos
      if (nn.gt.0) then
_IFN1(iv)               call pack(a(num2ep+1),lab1632,labout,numlabp)
_IF1(iv)            call pak4v(labij,a(num2ep+1))
         call put(a,m511,idev4)
_IFN1(iv)         do 480 iiii = 1 , 680
_IFN1(iv)            labout(iiii) = 0
_IFN1(iv) 480     continue
_IF1(iv)      call izero(680,labij,1)
      end if
      nn = m0
_IFN1(iv)       call pack(a(num2ep+1),lab1632,labout,numlabp)
_IF1(iv)            call pak4v(labij,a(num2ep+1))
      call put(a,m0,idev4)
      call chfopo(akm,maxa,mn,nofile(1),jblk(1),mblk(1),ifils,iblks,
     +  nocca,nsoc,nvirta)
      call clredx
      return
      end
_IFN(secd_parallel)
      subroutine symmu(qq,ibstar,skipp,iso,nshels)
c
c    symmetrise u-vectors ( chf solutions )
c    d2h and subgroups only
c
      implicit REAL  (a-h,o-z)
      logical skipp
INCLUDE(common/sizes)
      dimension skipp(3,nat)
      dimension qq(*),iso(nshels,*)
c
INCLUDE(common/nshel)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
      common/mpshl/ns(maxorb)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
      common/bufb/ptr(3,144),ict(maxat,8)
      common/symmos/imos(8,maxorb)
      character *8 grhf
      data grhf/'grhf'/
      data one/1.0d0/
c
      nav = lenwrd()
      call readi(iso,nw196(5)*nav,ibl196(5),ifild)
      call rdedx(ptr(1,1),nw196(1),ibl196(1),ifild)
c
      do 40 ii = 1 , nshell
         ic = katom(ii)
         do 30 it = 1 , nt
            id = iso(ii,it)
            ict(ic,it) = katom(id)
 30      continue
 40   continue
c
      nuniq = 0
      do 60 n = 1 , nat
         do 50 nop = 1 , nt
            if (ict(n,nop).ne.n) go to 60
 50      continue
         nuniq = n
         go to 70
 60   continue
 70   ntpls1 = noccb + 1
      nplus1 = nocca + 1
      nsoc = noccb - nocca
      nvirta = nsa4 - noccb
      ibll = lensec(mn)
      iblku = ibstar
      ioff = mn*3 + 1
      nat3 = nat*3
c     read in u vectors
      do 80 n = 1 , nat3
         call rdedx(qq(ioff),mn,iblku,ifils)
         iblku = iblku + ibll
         ioff = ioff + mn
 80   continue
      mn3 = mn*3
c
c
c     loop over vectors
      do 270 n = 1 , nat
         if (.not.(skipp(1,n))) then
            ioff = n*mn3
c     copy vectors for atom n into work area
c
            do 90 i = 1 , mn3
               qq(i) = qq(ioff+i)
 90         continue
c
c     zero all elements related to components of atom n
c     by symmetry
c
            nsame = 0
            do 110 iop = 1 , nt
               niop = ict(n,iop)
               if (niop.eq.n) nsame = nsame + 1
               ioff = niop*mn3
               do 100 i = 1 , mn3
                  qq(ioff+i) = 0.0d0
 100           continue
 110        continue
            nsame = max(nsame,1)
            an = one/dfloat(nsame)
c
c     work along the elements of this vector
c loop over double-single and double-virtual
c
            if (scftyp.eq.grhf) then
               ij = 0
               do 160 i = 1 , nsa4
                  do 150 ia = 1 , i
                     if (ns(i).ne.ns(ia)) then
                        ij = ij + 1
c     loop over symmetry operations
                        do 140 iop = 1 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)*an
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           do 130 nc = 1 , 3
                              ioff = (nc-1)*mn
                              npnc = (iop-1)*3 + nc
                              do 120 k = 1 , 3
                                 iof2 = (niop*3+k-1)*mn
                                 qq(iof2+ij) = qq(iof2+ij)
     +                              + sign*ptr(k,npnc)*qq(ioff+ij)
 120                          continue
 130                       continue
 140                    continue
                     end if
 150              continue
 160           continue
            else
               if (nocca.ne.0) then
                  do 210 i = 1 , nocca
                     do 200 ia = nplus1 , nsa4
                        ij = (ia-nocca-1)*nocca + i
c     loop over symmetry operations
                        do 190 iop = 1 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)*an
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           do 180 nc = 1 , 3
                              ioff = (nc-1)*mn
                              npnc = (iop-1)*3 + nc
                              do 170 k = 1 , 3
                                 iof2 = (niop*3+k-1)*mn
                                 qq(iof2+ij) = qq(iof2+ij)
     +                              + sign*ptr(k,npnc)*qq(ioff+ij)
 170                          continue
 180                       continue
 190                    continue
 200                 continue
 210              continue
               end if
               if (noccb.ne.nocca) then
c open shell only - loop over single-virtual
                  do 260 i = nplus1 , noccb
                     do 250 ia = ntpls1 , nsa4
                        ij = nvirta*nocca + (ia-nsoc-1)*nsoc + i - nocca
c     loop over symmetry operations
                        do 240 iop = 1 , nt
                           isign = imos(iop,i)*imos(iop,ia)
                           sign = dfloat(isign)*an
                           niop = ict(n,iop)
c     niop is the atom equivalent to n under operation
                           do 230 nc = 1 , 3
                              ioff = (nc-1)*mn
                              npnc = (iop-1)*3 + nc
                              do 220 k = 1 , 3
                                 iof2 = (niop*3+k-1)*mn
                                 qq(iof2+ij) = qq(iof2+ij)
     +                              + sign*ptr(k,npnc)*qq(ioff+ij)
 220                          continue
 230                       continue
 240                    continue
 250                 continue
 260              continue
               end if
            end if
         end if
 270  continue
c
c
c     translational invariance
c
      iof2 = nuniq*mn3
      if (nuniq.ne.0) then
         do 280 i = 1 , mn3
            qq(iof2+i) = 0.0d0
 280     continue
         do 300 n = 1 , nat
            if (n.ne.nuniq) then
               ioff = n*mn3
               do 290 i = 1 , mn3
                  qq(iof2+i) = qq(iof2+i) - qq(ioff+i)
 290           continue
            end if
 300     continue
      end if
c
c     write it all out again
c
      iblku = ibstar
      ioff = mn3 + 1
      lenuu = ibll*nat3
      call secput(isect(66),66,lenuu,iblko)
      lds(isect(66)) = mn*nat3
      call revind
      do 310 n = 1 , nat3
         call wrt3(qq(ioff),mn,iblku,ifils)
         call wrt3(qq(ioff),mn,iblko,ifild)
         iblku = iblku + ibll
         iblko = iblko + ibll
         ioff = ioff + mn
 310  continue
      return
      end
_ENDIF
      subroutine bfnshl(inshel,nsa)
c
c      determine what shell basis function belongs to
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension inshel(*)
INCLUDE(common/mapper)
INCLUDE(common/ghfblk)
c
c      loop over shells
c
      do 30 i = 1 , njk1
         ns = nbshel(i)
         il = ilfshl(i)
         do 20 nb = 1 , ns
            n = iactiv(il+nb)
c
c     basis function n is in shell i
c
            inshel(n) = i
 20      continue
 30   continue
      do 40 i = 1 , nsa
         inshel(i) = inshel(mapie(i))
 40   continue
      return
      end
_EXTRACT(wgrhf,_AND(hp800,i8))
      subroutine wgrhf(q,iq,alpha,beta)
c
c     'w matrix'   required in assembly of second derivatives
c      for general open-shell case
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical vir,out,occ
INCLUDE(common/infoa)
INCLUDE(common/nshel)
c
      common/mpshl/ns(maxorb)
      dimension q(*),iq(*),alpha(11,*),beta(11,*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
INCLUDE(common/ghfblk)
INCLUDE(common/atmblk)
INCLUDE(common/symtry)
INCLUDE(common/prnprn)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/blkin/g(510),nword
      common/maxlen/maxq
c
      vir(i) = ns(i).eq.njk1
      occ(i) = ns(i).ne.njk1
      out = odebug(16)
      call bfnshl(ns,nsa4)
      nat3 = nat*3
      nlen = nat3*nat3
      nsq = nsa4*nsa4
      netaa = nat3*nsq
      nzeta = njk1*nx
      novlp = nat3*nx
      iof = lenrel(nw196(5))
      iofs = nw196(5) + lenint(nat*nt)
c
      i10 = iofs + 1
      ioa1 = i10 + nlen
      iob1 = ioa1 + netaa
      ioc1 = iob1 + novlp
      iod1 = ioc1 + nx
      ioe1 = iod1 + nzeta
      nreq = ioe1 + nat3*mn
      if (nreq.gt.maxq) call caserr('insufficient core')
      call vclr(q(i10),1,nlen)
      ioa = ioa1
      call search(iochf(17),ifockf)
      do 20 n = 1 , nat3
         call reads(q(ioa),nsq,ifockf)
         ioa = ioa + nsq
 20   continue
      iob = iob1
      call search(iochf(14),ifockf)
      do 30 n = 1 , nat3
         call reads(q(iob),nx,ifockf)
         call actmot(q(iob),nsa4,mapie,iky)
         iob = iob + nx
 30   continue
      ioa = ioa1 - 1
      do 60 n = 1 , nat3
         do 50 i = 1 , nsa4
            do 40 j = 1 , i
               sum = q(ioa+(i-1)*nsa4+j)
               q(ioa+(i-1)*nsa4+j) = 2.0d0*q(ioa+(j-1)*nsa4+i)
               q(ioa+(j-1)*nsa4+i) = sum + sum
 40         continue
 50      continue
         ioa = ioa + nsq
 60   continue
      ioa = ioa1 - 1
      do 100 na = 1 , nat3
         iob = iob1 - 1
         do 90 nb = 1 , nat3
            sum = 0.0d0
            do 80 i = 1 , nsa4
               if (.not.(vir(i))) then
                  do 70 j = 1 , i
                     if (.not.(vir(j))) then
                        ij = iky(i) + j
                        sij = q(iob+ij)
                        if (i.eq.j) sij = sij*0.5d0
                        sum = sum +
     +                        sij*(q(ioa+(i-1)*nsa4+j)+
     +                             q(ioa+(j-1)*nsa4+i) )
                     end if
 70               continue
               end if
 80         continue
            q((na-1)*nat3+nb+i10-1) = q((na-1)*nat3+nb+i10-1) - sum
            iob = iob + nx
 90      continue
         ioa = ioa + nsq
 100  continue
      lenb = lensec(mn)
      ibeta = iblks + lenb*nat*6
      ibzeta = ibeta + lensec(nx)
      ioa = ioa1 - 1
      iob = iob1 - 1
      ioc = ioc1 - 1
      iod = iod1 - 1
      call lgrhfm(q(ioc1),ibeta,alpha,beta,fjk)
      call lgrhf(q(iod1),ibzeta,alpha,beta,fjk)
      do 140 n = 1 , nat3
         do 130 k = 1 , nsa4
            if (.not.(vir(k))) then
               do 120 i = 1 , nsa4
                  do 110 j = 1 , i
                     ik = min(i,k) + iky(max(i,k))
                     jk = min(j,k) + iky(max(j,k))
                     if (occ(j)) q(ioa+(j-1)*nsa4+i) = 
     +                     q(ioa+(j-1)*nsa4+i)
     +                   - 2.0d0*q(ioc+jk)*q(iob+ik)
     +                   - (q(ioc+ik)+q(iod+ik+(ns(j)-1)*nx))*q(iob+jk)
                     if (i.ne.j) then
                        if (occ(i)) q(ioa+(i-1)*nsa4+j)
     +                      = q(ioa+(i-1)*nsa4+j) - 2.0d0*q(ioc+ik)
     +                      *q(iob+jk)
     +                      - (q(ioc+jk)+q(iod+jk+(ns(i)-1)*nx))
     +                      *q(iob+ik)
                     end if
 110              continue
 120           continue
            end if
 130     continue
         ioa = ioa + nsq
         iob = iob + nx
 140  continue
      do 230 ifile = 1 , mmfile
         mblkk = kblk(ifile)
         idevm = nufile(ifile)
c        lblkm = nblk(ifile)
         call search(mblkk,idevm)
         call find(idevm)
 150     call get(g(1),nw)
         if (nword.gt.0) then
            if (nw.gt.0) then
               call find(idevm)
_IFN1(iv)               call unpack(g(num2e+1),lab816,labs,numlab)
_IF1(iv)               call upak8v(g(num2e+1),i205)
               do 220 int = 1 , nword
_IFN1(iv)                  kk2 = (int+int) + (int+int)
_IF(ibm,vax)
                  i = i205(int)
                  j = j205(int)
                  k = k205(int)
                  l = l205(int)
_ELSEIF(littleendian)
                  i = labs(kk2-2)
                  j = labs(kk2-3)
                  k = labs(kk2  )
                  l = labs(kk2-1)
_ELSE
                  i = labs(kk2-3)
                  j = labs(kk2-2)
                  k = labs(kk2-1)
                  l = labs(kk2)
_ENDIF
                  gg = -g(int)
                  if (i.eq.j) gg = gg*0.5d0
                  if (k.eq.l) gg = gg*0.5d0
                  if (i.eq.k .and. j.eq.l) gg = gg*0.5d0
                  ioa = ioa1 - 1
                  iob = iob1 - 1
                  if (occ(k) .and. occ(l)) then
                     kl = iky(k) + l
                     do 160 n = 1 , nat3
                        ijw = ioa + (j-1)*nsa4 + i
                        jiw = ioa + (i-1)*nsa4 + j
                        if (occ(j)) q(ijw) = q(ijw) + gg*q(iob+kl)
     +                      *(alpha(ns(j),ns(k))+alpha(ns(j),ns(l)))
     +                      *2.0d0
                        if (occ(i)) q(jiw) = q(jiw) + gg*q(iob+kl)
     +                      *(alpha(ns(i),ns(k))+alpha(ns(i),ns(l)))
     +                      *2.0d0
                        ioa = ioa + nsq
                        iob = iob + nx
 160                 continue
                     ioa = ioa1 - 1
                     iob = iob1 - 1
                  end if
                  if (occ(i) .and. occ(j)) then
                     ij = iky(i) + j
                     do 170 n = 1 , nat3
                        klw = ioa + (l-1)*nsa4 + k
                        lkw = ioa + (k-1)*nsa4 + l
                        if (occ(l)) q(klw) = q(klw) + gg*q(iob+ij)
     +                      *(alpha(ns(l),ns(i))+alpha(ns(l),ns(j)))
     +                      *2.0d0
                        if (occ(k)) q(lkw) = q(lkw) + gg*q(iob+ij)
     +                      *(alpha(ns(k),ns(i))+alpha(ns(k),ns(j)))
     +                      *2.0d0
                        ioa = ioa + nsq
                        iob = iob + nx
 170                 continue
                     ioa = ioa1 - 1
                     iob = iob1 - 1
                  end if
                  if (occ(i) .and. occ(k)) then
                     ik = iky(i) + k
                     do 180 n = 1 , nat3
                        jlw = ioa + (l-1)*nsa4 + j
                        ljw = ioa + (j-1)*nsa4 + l
                        if (occ(l)) q(jlw) = q(jlw) + gg*q(iob+ik)
     +                      *(beta(ns(l),ns(i))+beta(ns(l),ns(k)))
                        if (occ(j)) q(ljw) = q(ljw) + gg*q(iob+ik)
     +                      *(beta(ns(j),ns(i))+beta(ns(j),ns(k)))
                        ioa = ioa + nsq
                        iob = iob + nx
 180                 continue
                     ioa = ioa1 - 1
                     iob = iob1 - 1
                  end if
                  if (occ(j) .and. occ(l)) then
                     jl = min(j,l) + iky(max(j,l))
                     do 190 n = 1 , nat3
                        ikw = ioa + (k-1)*nsa4 + i
                        kiw = ioa + (i-1)*nsa4 + k
                        if (occ(k)) q(ikw) = q(ikw) + gg*q(iob+jl)
     +                      *(beta(ns(k),ns(j))+beta(ns(k),ns(l)))
                        if (occ(i)) q(kiw) = q(kiw) + gg*q(iob+jl)
     +                      *(beta(ns(i),ns(j))+beta(ns(i),ns(l)))
                        ioa = ioa + nsq
                        iob = iob + nx
 190                 continue
                     ioa = ioa1 - 1
                     iob = iob1 - 1
                  end if
                  if (occ(i) .and. occ(l)) then
                     il = iky(i) + l
                     do 200 n = 1 , nat3
                        jkw = ioa + (k-1)*nsa4 + j
                        kjw = ioa + (j-1)*nsa4 + k
                        if (occ(k)) q(jkw) = q(jkw) + gg*q(iob+il)
     +                      *(beta(ns(k),ns(i))+beta(ns(k),ns(l)))
                        if (occ(j)) q(kjw) = q(kjw) + gg*q(iob+il)
     +                      *(beta(ns(j),ns(i))+beta(ns(j),ns(l)))
                        ioa = ioa + nsq
                        iob = iob + nx
 200                 continue
                     ioa = ioa1 - 1
                     iob = iob1 - 1
                  end if
                  if (occ(j) .and. occ(k)) then
                     jk = min(j,k) + iky(max(j,k))
                     do 210 n = 1 , nat3
                        ilw = ioa + (l-1)*nsa4 + i
                        liw = ioa + (i-1)*nsa4 + l
                        if (occ(l)) q(ilw) = q(ilw) + gg*q(iob+jk)
     +                      *(beta(ns(l),ns(j))+beta(ns(l),ns(k)))
                        if (occ(i)) q(liw) = q(liw) + gg*q(iob+jk)
     +                      *(beta(ns(i),ns(j))+beta(ns(i),ns(k)))
                        ioa = ioa + nsq
                        iob = iob + nx
 210                 continue
                     ioa = ioa1 - 1
                     iob = iob1 - 1
                  end if
 220           continue
               go to 150
            end if
         end if
 230  continue
      ioe = ioe1 - 1
      ioa = ioa1 - 1
      call secget(isect(66),66,isec66)
      call search(isec66,ifild)
      do 240 n = 1 , nat3
         call reads(q(ioe+1),mn,ifild)
         ioe = ioe + mn
 240  continue
      ioe = ioe1 - 1
      do 280 na = 1 , nat3
         iob = iob1 - 1
         ioe = ioe1 - 1
         do 270 nb = 1 , nat3
            sum = 0.0d0
            ij = 0
            nr = 0
            do 260 i = 1 , nsa4
               do 250 j = 1 , i
                  ij = ij + 1
                  ijw = ioa + (j-1)*nsa4 + i
                  jiw = ioa + (i-1)*nsa4 + j
                  ss = q(iob+ij)
                  if (i.eq.j) ss = ss*0.5d0
                  sum = sum - (q(ijw)+q(jiw))*ss
                  if (ns(i).ne.ns(j)) then
                     nr = nr + 1
                     sum = sum + (q(ijw)-q(jiw))*q(ioe+nr)
                  end if
 250           continue
 260        continue
            q((nb-1)*nat3+na+i10-1) = q((nb-1)*nat3+na+i10-1) + sum
            iob = iob + nx
            ioe = ioe + mn
 270     continue
         ioa = ioa + nsq
 280  continue
      call rdedx(q(1),nw196(5),ibl196(5),ifild)
      if (out) then
         write (iwr,6010)
         call dr2sym(q(i10),q(ioa1),iq(1),iq(iof+1),nat,nat3,
     +               nshell)
         call prnder(q(i10),nat3,iwr)
      end if
      call secget(isect(60),60,isec46)
      call rdedx(q(ioa1),nlen,isec46,ifild)
      do 290 i = 1 , nlen
         q(ioa1-1+i) = q(ioa1-1+i) + q(i10-1+i)
 290  continue
      call dr2sym(q(ioa1),q(i10),iq(1),iq(iof+1),nat,nat3,
     +            nshell)
      call wrt3(q(ioa1),nlen,isec46,ifild)
      if (out) then
         write (iwr,6020)
         call prnder(q(ioa1),nat3,iwr)
      end if
      return
 6010 format (//' coupled hartree-fock contribution')
 6020 format (//' total so far')
      end
_ENDEXTRACT
      function aijkl(i,j,k,l,ns,alpha)
      implicit REAL  (a-h,o-z)
      dimension ns(*),alpha(11,11)
      aijkl = alpha(ns(j),ns(k)) + alpha(ns(i),ns(l))
     +        - alpha(ns(i),ns(k)) - alpha(ns(j),ns(l))
      return
      end
      function aijklx(i,j,k,l,ns,alpha)
      implicit REAL  (a-h,o-z)
      dimension ns(*),alpha(11,11)
      aijklx = -alpha(ns(j),ns(k)) + alpha(ns(i),ns(l))
     +         + alpha(ns(i),ns(k)) - alpha(ns(j),ns(l))
      return
      end
      subroutine ijmapr(num,inshel,nrmap,nr,nrx)
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/common)
INCLUDE(common/cndx41)
INCLUDE(common/cigrad)
      parameter (maxbfn=255)
      common/jspec/nspj(maxbfn)
c
      dimension nrmap(*),inshel(*)
c
      ioff(i) = i*(i-1)/2
c
      nr = 0
      ij = 0
      do 30 i = 1 , num
         do 20 j = 1 , i
            ij = ij + 1
            nrmap(ij) = 0
            if (inshel(i).ne.inshel(j)) then
               nr = nr + 1
               nrmap(ij) = nr
            end if
c
c     result : i and j in same shell - pair (i,j) is
c              redundant - nrmap(ij)=0
c
c            : i and j in different shells - pair(i,j)
c              non-redundant - nrmap(ij)=nr -
c              nr = position of non-redundant pair
c
 20      continue
 30   continue
c
      nrx = 0
      do 50 i = ncore + 1 , nocc
         do 40 j = 1 , ncore
            ij = ioff(i) + j
            if (nrmap(ij).eq.0) then
               nrx = nrx - 1
               nrmap(ij) = nrx
            end if
 40      continue
 50   continue
c
      do 70 i = nupact + 1 , ncoorb
         do 60 j = nocc + 1 , nupact
            ij = ioff(i) + j
            if (nrmap(ij).le.0) then
               nrx = nrx - 1
               nrmap(ij) = nrx
            end if
 60      continue
 70   continue
      do 90 i = ncore + 1 , nupact
         do 80 j = ncore + 1 , i - 1
            if (nspj(i).ne.nspj(j)) then
               ij = ioff(i) + j
               if (nrmap(ij).eq.0) then
                  nrx = nrx - 1
                  nrmap(ij) = nrx
               end if
            end if
 80      continue
 90   continue
c
      nrx = -nrx
c
c     nrx = no of additional independent pairs
c
      return
      end
      function ijkltp(i,j,k,l)
c=================================================================
c     classify integrals by coincidences between labels
c
      implicit REAL  (a-h,o-z)
      if (j.lt.k) then
         if (j.lt.l) then
            if (k.ne.l) then
               ijkltp = 14
               return
            else
               ijkltp = 11
               return
            end if
         else if (j.eq.l) then
            if (i.ne.k) then
               ijkltp = 9
               return
            else
               ijkltp = 5
               return
            end if
         else if (i.ne.k) then
            ijkltp = 13
            return
         else
            ijkltp = 7
            return
         end if
      else if (j.eq.k) then
         if (i.ne.j) then
            if (k.ne.l) then
               ijkltp = 8
               return
            else
               ijkltp = 3
               return
            end if
         else if (k.ne.l) then
            ijkltp = 2
            return
         else
            ijkltp = 1
            return
         end if
      else if (i.ne.j) then
         if (k.ne.l) then
            ijkltp = 12
            return
         else
            ijkltp = 10
            return
         end if
      else if (k.ne.l) then
         ijkltp = 6
         return
      else
         ijkltp = 4
         return
      end if
      end
      subroutine actmot(a,nsa,mapie,iky)
      implicit REAL  (a-h,o-z)
c     condenses triangular array so that it contains only
c     elements over active m.o.s
c
      dimension a(*),mapie(*),iky(*)
      ija = 0
      do 30 i = 1 , nsa
         do 20 j = 1 , i
            ija = ija + 1
            ij = iky(mapie(i)) + mapie(j)
            if (ija.gt.ij) go to 40
            a(ija) = a(ij)
 20      continue
 30   continue
      return
 40   call caserr('error in actmot')
      end
      subroutine ver_cphf(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/cphf.m,v $
     +     "/
      data revision /"$Revision: 6317 $"/
      data date /"$Date: 2015-03-13 21:56:17 +0100 (Fri, 13 Mar 2015) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
