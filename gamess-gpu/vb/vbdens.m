      subroutine natorbt(coeff,ndet,idet,icp,jcp,nelec,nalfa,dens1,dmo,
     &                   ipos,vnat,iortho,northo,nbasit,nmo,ncore,
     &                   superh,supers,superg)
c
c...  COMMENT STYLE - MARCIN
c...  c... - text note
c...  ccc  - commented source
c...  c    - empty line
c 
      implicit REAL (a-h,o-z), integer (i-n)
c
c     returned
c
c     dens1(nbasis*(nbasis+1)/2) : 1-density matrix  ao-basis (nbasis=nbasit)
c     dmo(nmo*(nmo+1)/2) : 1-density matrix  mo-basis 
c     vnat(nbasis,nbasis) natural orbitals incl. frozen core
c
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/gmemdata)
INCLUDE(../m4/common/gmempara) 
INCLUDE(../m4/common/vcore) 
INCLUDE(common/turtleparam)
c...  construct the one-electron density matrix and the natural orbitals
c...  currently also the 2-electron matrix and agragian are produced for optimise
c
      common /blkin/ potnuc,ppx,ppy,ppz,space(507)
INCLUDE(common/scftvb)
INCLUDE(common/ffile)
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/restri)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/timeperiods)
INCLUDE(../m4/common/restar)

INCLUDE(common/infato)
      common /energi/ enatom
INCLUDE(common/brill)
      dimension coeff(ndet),idet(nelec,ndet),icp(nelec),jcp(nelec),
     &          iortho(*),vnat(nbasit,nbasit),dens1(*),dmo(*),
     &          ipos(*),superh(*),superg(*),supers(*)
      common /davscf/ eshsst,thrssj,thrssd,maxssc,maxssv,maxssl,iprssd,
     &                alssr,firsss
c
INCLUDE(../m4/common/cndx40)
INCLUDE(../m4/common/atmol3)
c
c... for dynamic memory allocation debugging purpose, contains IGMEM_ vars.
c
INCLUDE(common/tractlt)
INCLUDE(common/vbcri)
c
      logical odoubl
      common/convb/odoubl
c
INCLUDE(common/vbtimess)
INCLUDE(../m4/common/funct)
INCLUDE(../m4/common/gjs)
INCLUDE(../m4/common/qice)
INCLUDE(../m4/common/runlab)
c
      character*8 modemkd1vb
c
      dimension array(5)
c
      data m1,m10,m13,m16/1,10,13,16/
c
      ind(i,j) = max(i,j)*(max(i,j)-1)/2 + min(i,j)
      modemkd1vb = 'mo'
c...    
c...  chicken...
c...
      if (nbasis.ne.nbasit) call caserr('unexpected nbasis in natorbt')
c
c...  ksao : s-matrix over ao's, ksmo : s-matrix over mo's  (dumped by vbtran)
c
      lenbas = nbasis*(nbasis+1)/2
      lenact = nmo*(nmo+1)/2
      ksao = igmem_alloc_inf(lenbas,'vbdens.m','natorbt','ksao',
     &                       IGMEM_DEBUG)
      ksmo = igmem_alloc_inf(lenact,'vbdens.m','natorbt','ksmo',
     &                       IGMEM_DEBUG)
c
      call get1e(Q(ksao),flop,'s',flop)
      call rdedx(Q(ksmo),lenact,iblhs+lensec(lenact),num3)
c     
      kh = igmem_alloc_inf(lenbas+1,'vbdens.m','natorbt','kh',
     &                        IGMEM_DEBUG)
      kt = igmem_alloc_inf(lenbas+1,'vbdens.m','natorbt','kt',
     &                        IGMEM_DEBUG)
      call get1e(Q(kh),potn,'h',Q(kt))
      call gmem_free_inf(kt,'vbdens.m','natorbt','kt')
      call gmem_free_inf(kh,'vbdens.m','natorbt','kh')
      ntot = ncore + nmo
      odoubl=.true.
      coulomb  = 0.0d0
      exchange = 0.0d0
      eleone   = 0.0d0
c
      lentot = ntot*(ntot+1)/2
      lenkd1t = lentot*2
c...   lenkd1 by analogy with casa, but not understanding
      len2 = lenact*(lenact+1)/2

      kl    = igmem_alloc_inf(lenact,'vbdens.m','natorbt','kl',
     &                        IGMEM_DEBUG)
      kd1   = igmem_alloc_inf(lenact,'vbdens.m','natorbt','kd1',
     &                        IGMEM_DEBUG)
      kd1t  = igmem_alloc_inf(lenkd1t,'vbdens.m','natorbt','kd1t',
     &                        IGMEM_DEBUG)
      kd2   = igmem_alloc_inf(len2,'vbdens.m','natorbt','kd2',
     &                        IGMEM_DEBUG)
      klt   = igmem_alloc_inf(lenbas,'vbdens.m','natorbt','klt',
     &                        IGMEM_DEBUG)

c
      islen = nalfa*nalfa + (nelec-nalfa)*(nelec-nalfa)
c
c...  lenbas length was too small in some cases, because of REAL HUGE
c...  dimension inconsistencies in few subroutines, dimension check has 
c...  been done, and correct dimension for ks is: number of alfa_electrons 
c...  squared + number of beta_electros squares (marcin)
ccc      ks    = igmem_alloc_inf(lenbas,'vbdens.m','natorbt','ks',
c
      ks    = igmem_alloc_inf(islen,'vbdens.m','natorbt','ks',
     &                        IGMEM_DEBUG)
c...  kvecc length might be too small (number of orbitals * nbasis)
      kvecc = igmem_alloc_inf(max(ntot,nbasis)*nbasis,'vbdens.m',
     &                        'natorbt','kvecc',IGMEM_DEBUG)

c...  kvec - allocating memory isnt necessary - we'r not using it here anyway,
c...         not until next mem. allocation
ccc      kvec  = igmem_alloc_inf(nbasis*nbasis,'vbdens.m','natorbt','kvec',
ccc     &                        IGMEM_DEBUG)

      nsize = 2*nelec*nelec + (nelec*(nelec+1)/2)**2 + nelec**3
      kscr  = igmem_alloc_inf(max(nsize,nbasis*(nbasis+1)/2),'vbdens.m',
     &                    'natorbt','kscr',IGMEM_DEBUG)

      call vclr(Q(kl),1,lenact)
      call vclr(Q(kd1),1,lenact)
      call vclr(Q(kd2),1,len2)
c
c...  construct one- and two-electron density matrix and lagrangian
c
      a1 = cpulft(1)
      call start_time_period(TP_VB_LADM)
      if (zruntp.ne.'scf') then
c
_IF(parallel)
         call pg_dlbchunk(1,.false.)
         call pg_dlbreset()
         icounter = 0
         ido = -1 
_ENDIF
         do 40 i=1,ndet
            do 30 j=1,i
_IF(parallel)
               icounter = icounter + 1
               if (ido.lt.icounter) ido = ipg_dlbtask()
               if (icounter.eq.ido) then 
_ENDIF
                  call icopy(nelec,idet(1,i),1,icp,1)
                  call icopy(nelec,idet(1,j),1,jcp,1)
                  dprod = coeff(i) * coeff(j)
                  if (i.ne.j) dprod=dprod*2 
c...  MKLD1d2 SUBROUTINE STILL USING OLD MEMORY PARTITIONING
                  call mkld1d2(Q(kl),Q(kd1),
     +                         Q(kd2),dprod,evb-potn,
     +                         icp,jcp,supers,superh,superg,
     +                         nelec,nalfa,nmo,Q(ks),
     +                         Q(kscr),dtotal,iwr)
_IF(parallel)
               endif
_ENDIF
30          continue
40       continue
_IF(parallel)
      call pg_dgop(17120,Q(kl),lenact,'+')
      call pg_dgop(17121,Q(kd1),lenact,'+')
      call pg_dgop(17122,Q(kd2),len2,'+')
_ENDIF
      else
        modemkd1vb = 'ao'
        call mkd1vb(coeff,ndet,idet,icp,jcp,nelec,nalfa,Q(kscr),
     +              Q(kd1),ipos,Q(ksmo),vnat,iortho,
     +              northo,nbasis,nmo,ncore,iprint,'ao')
      end if 
      call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
      a1 = cpulft(1) - a1
      tlagr = tlagr + a1
      call end_time_period(TP_VB_LADM)
c
c..   save 1-el density on mo basis
      call fmove(Q(kd1),dmo,lenact)
c
c... calculate 1 electron energy ao density matrix
c
      a1 = cpulft(1)
      call start_time_period(TP_VB_DTRAN)
      call fillqpar(nmo,ncore,nbasis)
c 
      kvb7_transvb = kscra7vb('kvb7_transvb',(ncore+nsa)*nbasis,'r','r')
      call rdedx(Q(kvecc),(ncore+nsa)*nbasis,kvb7_transvb,num8)
      if (ncore+nsa.ne.ntot) call caserr('vectors dim wrong - vbdens')
*
      kscr = igmem_alloc_all_inf(2*nbasis,'vbdens.m','natorbt',
     &                           'kscr',IGMEM_DEBUG)
c...  reorthogonalise frozen core
      call normvc(Q(kvecc),Q(ksao),Q(kscr),nbasis,
     +            ncore,cridep)
      call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
c
c...    frozen core 
c...    1-density OK - taken care of by pi2
c...    2 0 0
c...    0 2 0
c...    0 0 2
c...    2-density not done
c...    iiii : 1
c...    iijj : 4
c...    ijij : -1
c...    lagarangian not done
c...    Fock-matrix
       if (zruntp.ne.'scf'.and.ncore.gt.0) 
     1  call caserr('frozen 2-density to be done')
c
ccc        write(iwr,*) '** frozen core gradients are **NOT** ok **'
c
c...    move 1-density to ncore+ spacing in kd1t
c
       call vclr(Q(kd1t),1,lenkd1t)
       ll = 0
       do i=ncore+1,ntot
        do j=1,i
          if (j.gt.ncore) then
            kk=ic1e(i,1)+ic1e(j,2)-1 
            Q(kd1t+kk) = Q(kd1+ll)
              ll = ll + 1
          end if
        end do
       end do
c
c...    get ao density matrix in dens1 
c...    dump it to disk always
c
       call vclr(dens1,1,lenbas)
       kmaxmem = igmem_max_memory()
       kmaxmem = kmaxmem/10
       kscr = igmem_alloc_all_inf(kmaxmem,'vbdens.m','natorbt',
     &                            'kscr',IGMEM_DEBUG)
       nsave=nprint
       if (iprint.lt.1000) nprint=-5
       call p1out(Q(kscr),Q(kd1t),Q(kd2),iwr,
     +            nprint)
       call tp2out(Q(kd1t),Q(kd2),iwr)
       call pi2(Q(kvecc),dens1,Q(kd1t),nprint)
c...    pi2 does the scaling of the density matrix by itself
       nprint=nsave

       call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
c
c...  dens1 now contains the density matrix on ao basis
c
       if (zruntp.ne.'scf') then  
c...     transform 2-density + lagrangian
         call wrt3(Q(kvecc),nblkq4,iblkq4,ndump4)
         kmaxmem = igmem_max_memory()
         call inipi4(kmaxmem,ntot)
         kscr = igmem_alloc_all_inf(kmaxmem,'vbdens.m','natorbt',
     &                              'kscr',IGMEM_DEBUG)
         call pi4(Q(kscr))
         call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
         call tmoden(Q(kvecc),Q(klt),Q(kl),10)
       end if
c
       a1 = cpulft(1) - a1
       tgtr = tgtr + a1
       call end_time_period(TP_VB_DTRAN)
c
c... save energy for optimisation algorithm and for final outputs
c
       enrgy = evb
c
       array(1) = potn
       array(2) = evb-potn
       array(3) = evb
       array(4) = 0.0e0
       array(5) = 0.0e0
       call secput(isect(494),m16,m1,iblk9)
       call wrt3(array,m10,iblk9,num3)
c
c...  bring first order density matrix to orthogonal basis
c
c...  transform density matrix (covariant tensor) step 1
c...  not yet the transformation to the orthogonal basis
c
       kscr  = igmem_alloc_inf(max(nsize,nbasis*(nbasis+1)/2,nmo*nmo),
     &         'vbdens.m','natorbt','kscr',IGMEM_DEBUG)
       do i=2,nmo
          do  j=1,i-1
             Q(kd1 +i*(i-1)/2+j-1) = dmo (i*(i-1)/2+j)/2
          end do
       end do
      call trtrtr(Q(ksmo),Q(kd1),Q(kd1),nmo,
     +            Q(kscr))
      call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
c

      ktran = igmem_alloc_inf(nmo*nmo,'vbdens.m','natorbt','ktran',
     &                        IGMEM_DEBUG)
      ke  = igmem_alloc_inf(max(ntot,nbasis),'vbdens.m','natorbt','ke',
     &                        IGMEM_DEBUG)
      kdeno = igmem_alloc_inf(nmo*(nmo+1)/2,'vbdens.m','natorbt',
     &                        'kdeno',IGMEM_DEBUG)
      ktra2 = igmem_alloc_inf(nmo*nmo,'vbdens.m','natorbt','ktra2',
     &                        IGMEM_DEBUG)
      kscr  = igmem_alloc_inf(2*(nmo*nmo),'vbdens.m','natorbt','kscr',
     &                        IGMEM_DEBUG)
c
c...  metric is saved in Q(ksmo) in case schmidt does not work
c
      ntroub = 0
      call fmove(Q(ksmo),Q(kscr),lenact)
80    continue
c
c...  determine transformation matrix
c...  i.e. orthogonalise the mo's
c
      call schmidt(Q(kscr),Q(ktran),nmo,itroub)
c
      if (itroub.ne.0) then
         ntroub = ntroub + 1
         if ( ntroub .eq. 1 ) write(iwr,90)
90       format(//,' *************** warning ***************',/,
     &             '  vbscf-mo metric contains dependencies!',/,
     &             ' ***************************************')
         if (ntroub.eq.nmo)
     &   call vberr('1-electron density matrix is empty ?')
         do 100 i=1,nmo
            Q( kscr+ind(i,itroub)-1 ) = 0.0d0
            Q(kd1-1+ ind(i,itroub) ) = 0.0d0
100      continue
         Q( kscr+ind(itroub,itroub)-1 ) = 1.0d0
         goto 80
      end if
c
      if (ntroub.ne.0) then
        write(iwr,110) ntroub
        write(iwr,*) ' '
      end if
110   format(/,' there seem to be ',i2,' superfluous orbitals in this',
     &         ' wavefunction')
c
c...  transform density matrix step 2
c...  Q(kdeno) now has the density matrix in the orthogonal basis
c
c

      call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
      kscr = igmem_alloc_inf(2*(nmo*nmo),'vbdens.m','natorbt','kscr',
     &                       IGMEM_DEBUG)
      call mult11(Q(kd1),Q(kdeno),Q(kscr),nmo,nmo,
     &            Q(ktran),Q(ktra2))
c
      call vclr(Q(kscr),1,nmo*(nmo+1)/2)
c      do i=1,nmo
c         Q(kscr-1+i*(i+1)/2) = 1.0d0
c      end do
c     print *,' remco ortho ',tracep(Q(kscr),Q(kdeno),nmo)
c...  should give # active electrons
c...  diagonalise deno using the orthogonalised mo's as "unit-matrix"
c
      call vclr(Q(ke),1,nbasis)
      call jacobt(Q(kdeno),iky,nmo,Q(ktran),nmo,
     +            Q(ke),1,3,crilow,Q(kscr))
c
c...  Q(ktran) now contains the natural orbitals in the basis of the
c...  occupied orbitals (i.e. the final orbitals)
c
      call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
      call gmem_free_inf(ktra2,'vbdens.m','natorbt','ktra2')
      call gmem_free_inf(kdeno,'vbdens.m','natorbt','kdeno')
      kvec = igmem_alloc_inf(nbasis*ntot,'vbdens.m','natorbt','kvec',
     &                       IGMEM_DEBUG)
c
c...  core orbitals are in front
c...  get last vectors from 33
c...  better from ed3
c
_IF(atmol)
      rewind 33
      if (nscf.gt.0) then
c...     read some old info first
         read(33) ndum,(Q(ij),ij=kvec,kvec+ndum-1)
         read(33) nb,na,(Q(ij),ij=kvec,kvec+nb*na-1)
      end if
      read(33) nb,na,(Q(ij),ij=kvec,kvec+nb*na-1)
_ELSE
cremco    note kvec use weird      call getqvb(Q(kvec),nbasis,nmo_ncore,isecv,'nopr')
      kvb7_transvb = kscra7vb('kvb7_transvb',(ncore+nsa)*nbasis,'r','r')
      call rdedx(Q(kvec),(ncore+nsa)*nbasis,kvb7_transvb,num8)
_ENDIF
c
c...  kvec should start at the mo position
c...  transform the natural orbitals to the basis of ao's
c
      call vclr(vnat(1,ncore+1),1,(nbasis-ncore)*nbasis)
      call mxmb(Q(kvec+ncore*nbasis),1,nbasis,Q(ktran),1,
     +          nmo,vnat(1,ncore+1),1,nbasis,nbasis,nmo,nmo)
c
c...  move core orbitals before the natural orbitals (for dump)
c
      call fmove(Q(kvec),vnat(1,1),nbasis*ncore)
      call gmem_free_inf(kvec,'vbdens.m','natorbt','kvec')
      do i=1,nmo
         Q(ke+ntot-i) = Q(ke+nmo-i)
      end do
      do i=1,ncore
         Q(ke+i-1) = 2.0d0
      end do
c
c...  empty natorbs have stll occ 0.0d0
c
c...  the natural orbitals that have occ=2 sometimes look a bit weird
c...  e.g. they may not be symmetry adapted. this is caused by jacobi
c...  via thrssj and doesn't alter the properties that are calculated
c...  you may however consider a canonicalisation to restore symmetry
c...  in case of localised orbitals this is perhaps the only solution
c
      if (nscf.eq.0) then
         write(iwr,120)
120      format(/,' natural orbitals :')
         call prvc(vnat,ntot,nbasis,Q(ke),'v','l')
      end if
c
c...  dump the natural orbitals if requested
c...  most logical place is mouta 
c 
      call putqnatorb(vnat,Q(ke),Q(ke),nbasis,nbasis,
     +                mouta)
c
      nints = nbasis*(nbasis+1)/2
      kscr = igmem_alloc_inf(nbasis*(nbasis+1)/2,'vbdens.m','natorbt',
     &                       'kscr',IGMEM_DEBUG)
      ksc2 = igmem_alloc_inf(nbasis*(nbasis+1)/2,'vbdens.m','natorbt',
     &                       'ksc2',IGMEM_DEBUG)
      call get1e(Q(kscr),potn,'h',Q(ksc2))
      honele = tracep(Q(kscr),dens1,nbasis)
      call get1e(Q(kscr),dummy,'t',Q(ksc2))
      hkinet = tracep(Q(kscr),dens1,nbasis)
      call gmem_free_inf(ksc2,'vbdens.m','natorbt','ksc2')
      call gmem_free_inf(kscr,'vbdens.m','natorbt','kscr')
      hpoten = evb - hkinet
      electr = evb - potn
      electrons = tracep(Q(ksao),dens1,nbasis) 
c
      if (scfconv.or.(nscf.eq.0)) then 
      write(iwr,22) evb,electr,potnuc,core-potnuc,
     &              honele,hkinet,hpoten,honele-electr,hpoten/hkinet,
     &              electrons
22    format(/,' ====================================================',
     &       /,'             total energy ',f27.15,
     &       /,'        electronic energy ',f27.15,
     &       /,' nuclear repulsion energy ',f27.15,
     &       /,'                   E-core ',f27.15,
     &       /,'        1-electron energy ',f27.15,
     &       /,'           kinetic energy ',f27.15,
     &       /,'         potential energy ',f27.15,
     &       /,'        2-electron energy ',f27.15,
     &       /,'          virial quotient ',f27.7,
     &       /,'              # electrons ',f27.14,
     &       /,' ====================================================')
      endif
c
      if (modemkd1vb.ne.'ao') then
c
c...  dens1 ontains the density matrix on ao basis
c
         if (iprins.gt.1000.or.iprint.gt.1000) then
            write(iwr,160)
160         format(/,' one-electron density matrix in ao basis :')
            call tripri(dens1,nbasis)
         end if
c
c...  store ao density matrix on disk (for convergence criterium or as
c...  basis for the fock matrix, that might be built)
c
         nn = nbasis * (nbasis + 1) /2
         kvb7_dn = kscra7vb('kvb7_dn',nn,'r','n')
         if (kvb7_dn.lt.0) then
c...  write new density matrix to disk
            kvb7_dn = kscra7vb('kvb7_dn',nn,'r','w')
            call wrt3(dens1,nn,kvb7_dn,num8)
c...  write zeroes to "old" density matrix
            call vclr(Q(kscr),1,nn)
            kvb7_do = kscra7vb('kvb7_do',nn,'r','w')
            call wrt3(Q(kscr),nn,kvb7_do,num8)
         else
c...  make "new" density "old"
            flip = flip_scra7vb('kvb7_dn','kvb7_do')
c...  write new density to disk
            kvb7_dn = kscra7vb('kvb7_dn',nn,'r','w')
            call wrt3(dens1,nn,kvb7_dn,num8)
         endif
         call wrt3(dens1,nn,ibl3pavb(),idaf)
      end if
c
      if (enatom.ne.0.0d0) then
c...     use hand-given atomic energy to print bonding energy
         ebondh = evb - enatom
c...     hartree to joule
         htoj = 4.359814d-18
c...     joule to calorie
         rjtoc = 0.2390057d0
c...     joule to electronvolt
         rjtoev = 0.6241457d19
c...     joule to reciprocal centimeter
         rjtocm = 0.5035246d23
c...     avogadro's number
         avoga = 6.022045d23
c...     hartree to kelvin
         htok = 3.15777d5
         if (scfconv.or.(nscf.eq.0)) then
         write (iwr,111) ebondh,
     &                 ebondh * htoj * avoga / 1000. ,
     &                 ebondh * htoj * avoga * rjtoc / 1000. ,
     &                 ebondh * htoj * rjtoev,
     &                 ebondh * htoj * rjtocm,
     &                 ebondh * htok,
     &                 ebondh * htoj * avoga/ 33000.d0
111      format(/,9x,'  bonding energy ',e21.15,' hartree',
     &          /,9x,'                 ',e21.15,' kilojoule / mole',
     &          /,9x,'                 ',e21.15,' kilocalorie / mole',
     &          /,9x,'                 ',e21.15,' eV',
     &          /,9x,'                 ',e21.15,' cm-1',
     &          /,9x,'                 ',e21.15,' kelvin',
     &          /,9x,'               ~ ',e21.15,' (horsepower/mole)',
     &                                             '.second')
         endif
      end if
      if ((nitscf.gt.1).and.(iprint.gt.10000)) write(iwr,77) swave
77    format(//,' overlap of the current wavefunction with the previous'
     &         ,' one :',f17.14)

ccc      call gmem_free_set(kl,ke)
      call gmem_free_inf(ke,'vbdens.m','natorbt','ke')
      call gmem_free_inf(ktran,'vbdens.m','natorbt','ktran')
      call gmem_free_inf(kvecc,'vbdens.m','natorbt','kvecc')
      call gmem_free_inf(ks,'vbdens.m','natorbt','ks')
      call gmem_free_inf(klt,'vbdens.m','natorbt','klt')
      call gmem_free_inf(kd2,'vbdens.m','natorbt','kd2')
      call gmem_free_inf(kd1t,'vbdens.m','natorbt','kd1t')
      call gmem_free_inf(kd1,'vbdens.m','natorbt','kd1')
      call gmem_free_inf(kl,'vbdens.m','natorbt','kl')
c
      call gmem_free_inf(ksmo,'vbdens.m','natorbt','ksmo')
      call gmem_free_inf(ksao,'vbdens.m','natorbt','ksao')
c      
      return
      end
************************************************************************
      integer function ibl3pavb()
c     interface to transfer ibl3pa from dump3
INCLUDE(../m4/common/dump3)
       ibl3pavb = ibl3pa
      return
      end        
c***********************************************************************
      subroutine weigh2(w,ipos,ig,nblock,ir,ic,s,scr1,scr2,scr3,
     &                  nelec,nalfa,dprod,na,n1,ntwo)
c
      implicit REAL (a-h,o-z) , integer   (i-n)
c
c.....
      logical equal,exchange
c.....
c.....dimension arrays : = nelec
c.....
      dimension ir(*),ic(*)
c.....
c.....                   = nelec**2
c.....
      dimension s(*)
c.....
c.....                   = 5 * nblock
c.....
      dimension ig(5,*)
c.....
c.....                   = (nelec*(nelec-1)/2)**2
c.....
      dimension ipos(*),w(*),scr1(*),scr2(*),scr3(*)
      external iparity
c.....
INCLUDE(common/vblimit)
c.....
      det    = 0.0d0
      n1 = 0
      na = 0
      ntwo = 0
      n2 = 0
      nt = 0
      ipar = 1
      if (nsing.eq.0) then
c.....
         icase = 1
c.....
c
c        x x x . . . . . . . . .
c        x x x . . . . . . . . .
c        x x x . . . . . . . . .
c        . . . x x x . . . . . .
c        . . . x x x . . . . . .
c        . . . x x x . . . . . .
c        . . . . . . x x x . . .
c        . . . . . . x x x . . .
c        . . . . . . x x x . . .
c        . . . . . . . . . x x x
c        . . . . . . . . . x x x
c        . . . . . . . . . x x x
c
c.....
c.....   no singularities, therefore a straightforward calculation
c.....
         det = dprod
c.....
c.....   one-electron contribution per block
c.....
         do 10 i=1,nblock
            if (i.le.ialfa) na = na + ig(1,i)*ig(1,i)
            call cik( s(ig(5,i)), w(ig(5,i)), scr1,scr2,ig(1,i))
10       continue
         nt = ig(5,nblock) + ig(1,nblock) * ig(1,nblock)
         n1 = nt - 1
c.....
c.....   two electron contribution involving one block at a time
c.....
         do 20 i=1,nblock
            call cikjl(w(nt),ig(1,i),w(ig(5,i)))
            ii  = ig(1,i)*(ig(1,i)-1)/2
            nt  = nt + ii * ii
20       continue
         n2a = nt - n1  - 1
         call wmix(w(nt),w,nblock,ig,n2b)
         nt  = nt  + n2b - 1
         n2  = n2a + n2b
c.....
c.....   now determine integral addresses
c.....
         call pik(ipos,ir,ic,ig,nblock)
         n   = n1 + 1
         call pikjl(ipos(n),ipos(n2+n),ir,ic,ig,nblock)
c.....
c.....   mixed contributions
c.....
         n = n + n2a
         call gmix(ipos(n),ipos(n2+n),ir,ic,ig,nblock,ialfa)
c.....
      else if (nsing.eq.1) then
c.....
         if (nrectan.eq.0) then
c.....
            if (ifix.eq.0) then
c.....
               icase = 2
c.....
c
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               call c00( s(ig(5,is0)),ig(1,is0),w )
               n1 = ig(1,is0) * ig(1,is0)
               if (is0.le.ialfa) na = n1
               n  = n1 + 1
c.....
c.....         two electron part involving "true" second order cofactors
c.....         of the singular block
c.....
               call c0000(ig(1,is0),w(n),scr1,scr2,scr3,s(ig(5,is0)))
               n2a = (ig(1,is0) * (ig(1,is0)-1) / 2)
               n2a = n2a * n2a
               n   = n + n2a
c.....
c.....         mixed contributions involving the singular block always
c.....
               iscr = 1
               do 60 i=1,nblock
                  if(i.ne.is0) then
                     call cik(s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
                     iscr = iscr + ig(1,i) * ig(1,i)
                  end if
60             continue
               call wmix0(w(n),w,n1,scr1,iscr-1,n2b)
               nt = n + n2b
               call p00( ipos,ir(ig(3,is0)),ic(ig(4,is0)),ig(1,is0) )
               n  = n1 + 1
               call p0000(ipos(n),ipos(nt),ir(ig(3,is0)),ic(ig(4,is0)),
     &                                                        ig(1,is0))
               call gmix0(ipos(n+n2a),ipos(nt+n2a),ir,ic,ig,nblock,is0,
     &                                                            ialfa)
               nt = nt - 1
c.....
            else
c.....
               icase = 3
c.....
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . . . . . . . . . .
c              . . . . x x . . . . . .
c              . . . . x x . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
c.....         for one-electron part just one integral
c.....
               ipar = iparity(ig)
               irf     = ir(ifix)
               icf     = ic(kfix)
               ipos(1) = max(irf,icf)*(max(irf,icf)-1)/2+min(irf,icf)
               n1      = 1
               if (ifix.le.nalfa) na = 1
               w(1)    = 1.0d0
c.....
c.....         second order cofactors are first order really
c.....
               do 50 i=1,nblock
                  call cik( s(ig(5,i)),w(ig(5,i)+1),scr1,scr2,ig(1,i))
50             continue
c.....
               nt = ig(5,nblock) + ig(1,nblock) * ig(1,nblock)
               call pik00(ipos(2),ipos(nt+1),ir,ic,ifix,kfix,ig,
     &                                               nblock,nalfa,ialfa)
            end if
c.....
         else if(nrectan.eq.1) then
c.....
            if (ifix.ne.0) then
c.....
               icase = 4
c.....
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . x x x . . . . . .
c              . . . x x x . . . . . .
c              . . . x x x . . . . . .
c              . . . . . . . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
               ipar = iparity(ig)
c.....
c.....         one electron part involves those choices of k that make
c.....         the singular block become square
c.....
               call c0k( s(ig(5,is1)),ig(2,is1),w )
               n1 = ig(2,is1)
               if (is1.le.ialfa) na = n1
               n  = n1 + 1
c.....
c.....         two electron part involving "true" second order cofactors
c.....         of the singular block
c.....
               call c0kjl(ig(2,is1),w(n),scr1,scr2,scr3,s(ig(5,is1)))
               n2a = (ig(2,is1) * (ig(2,is1)-1) / 2) * ig(1,is1)
               n   = n + n2a
c.....
c.....         mixed contributions involving the rectangle always
c.....
               iscr = 1
               do 67 i=1,nblock
                  if(i.ne.is1) then
                     call cik(s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
                     iscr = iscr + ig(1,i) * ig(1,i)
                  end if
67             continue
               call wmix0(w(n),w,ig(2,is1),scr1,iscr-1,n2b)
               nt = n + n2b
               call p0k( ipos,ir(ifix),ic(ig(4,is1)),ig(2,is1) )
               n  = n1 + 1
               call p0kjl(ipos(n),ipos(nt),ir(ifix),ir(ig(3,is1)),
     &                                             ic(ig(4,is1)),ig,is1)
               call gmix0k(ipos(n+n2a),ipos(nt+n2a),ir,ifix,ic,ig,
     &                                         nblock,nalfa,ialfa,is1)
               nt = nt - 1
c.....
            else
c.....
               icase = 5
c.....
c
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              . . x x x . . . . . . .
c              . . x x x . . . . . . .
c              . . x x x . . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               ipar = iparity(ig)
c.....
c.....         one electron part involves those choices of i that make
c.....         the singular block become square
c.....
               call ci0t( s(ig(5,is1)),ig(1,is1),w )
               n1 = ig(1,is1)
               if (is1.le.ialfa) na = n1
               n  = n1 + 1
c.....
c.....         two electron part involving "true" second order cofactors
c.....         of the singular block
c.....
               call ci0jl(ig(1,is1),w(n),scr1,scr2,scr3,s(ig(5,is1)))
               n2a = (ig(1,is1) * (ig(1,is1)-1) / 2) * ig(2,is1)
               n   = n + n2a
c.....
c.....         mixed contributions involving the rectangle always
c.....
               iscr = 1
               do 70 i=1,nblock
                  if(i.ne.is1) then
                     call cik(s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
                     iscr = iscr + ig(1,i) * ig(1,i)
                  end if
70             continue
               call wmix0(w(n),w,ig(1,is1),scr1,iscr-1,n2b)
               nt = n + n2b
               call pi0( ipos,ir(ig(3,is1)),ig(1,is1),ic(kfix))
               n  = n1 + 1
               call pi0jl(ipos(n),ipos(nt),ic(kfix),ir(ig(3,is1)),
     &                                             ic(ig(4,is1)),ig,is1)
               call gmixi0(ipos(n+n2a),ipos(nt+n2a),ir,ic,kfix,ig,
     &                                         nblock,nalfa,ialfa,is1)
               nt = nt - 1
c.....
            end if
c.....
         else
c.....
c.....      as far as the singly singular cases are concerned the only
c.....      possibilty left is two rectangular blocks. make sure is1
c.....      always refers to the one that has more rows than columns
c.....
c
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . . . . x x x . . .    or   . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c
c.....
            icase = 6
c.....
            if (ig(1,is1).lt.ig(2,is1)) then
               iii = is1
               is1 = is2
               is2 = iii
               end if
            ipar = iparity(ig)
c.....
c.....      one electron part
c.....
            ist = ig(1,is1) + ig(2,is2) + 1
            if (is1.le.ialfa) na = n1
            call ci0t(s(ig(5,is1)),ig(1,is1),w             )
            call c0k(s(ig(5,is2)),ig(2,is2),w(ig(1,is1)+1))
            call wmix0(w(ist),w(ig(1,is1)+1),ig(2,is2),
     &                        w             ,ig(1,is1),n1)
            n1 = ist + n1 -1
            if (is1.le.nalfa) na = n1
c.....
c.....      second order cofactors of first rectangle
c.....
            n    = n1 + 1
            n2a  = ig(1,is1) * (ig(1,is1)-1) * ig(2,is1) / 2
            iscr = n + n2a * ig(2,is2)
            call ci0jl(ig(1,is1),w(iscr),scr1,scr2,scr3,s(ig(5,is1)))
            call wmix0(w(n),w(ig(1,is1)+1),ig(2,is2),
     &                      w(iscr       ),n2a,nn)
            n2a = n2a * ig(2,is2)
            n   = n + nn
c.....
c.....      second order cofactors of second rectangle
c.....
            n2b  = ig(2,is2) * (ig(2,is2)-1) * ig(1,is2) / 2
            iscr = n + n2b * ig(1,is1)
            call c0kjl(ig(2,is2),w(iscr),scr1,scr2,scr3,s(ig(5,is2)))
            call wmix0(w(n),w             ,ig(1,is1),
     &                      w(iscr)       ,n2b,nn)
            n2b = n2b * ig(1,is1)
            n   = n + nn
c.....
c.....      mixed part, involving the two rectangles always
c.....
            iscr = 1
            do 80 i=1,nblock
               if(i.ne.is1.and.i.ne.is2) then
                  call cik( s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
                  iscr = iscr + ig(1,i) * ig(1,i)
               end if
80          continue
            call wmix0(w(n),w(ist),n1,scr1,iscr-1,n2c)
            nt = n1 + n2a + n2b + n2c
            call pab(ipos,ir(ig(3,is1)),ig(1,is1),
     &                    ic(ig(4,is2)),ig(2,is2))
            call pabaa(ipos(n1+1),ipos(nt+1),ir(ig(3,is1)),ig(1,is1),
     &                         ic(ig(4,is1)),ir(ig(3,is2)),
     &                         ic(ig(4,is2)),              ig(2,is2))
            n = n1 + n2a + n2b + 1
            call gmixab(ipos(n),ipos(nt+n2a+n2b+1),ir,ic,ig,nblock,
     &                                                  ialfa,is1,is2)
c.....
         end if
c.....
      else
c.....
c.....   two singularities in the overlap matrix
c.....
         if (nrectan.eq.0) then
c.....
            if (ifix.eq.0) then
c.....
               if (is02.ne.0) then
c.....
                  icase = 7
c.....
c
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 . . . 0 0 0 . . . . . .
c                 . . . 0 0 0 . . . . . .
c                 . . . 0 0 0 . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . 0 0 0
c                 . . . . . . . . . 0 0 0
c                 . . . . . . . . . 0 0 0
c
c.....
                  na = ig(1,is0 ) * ig(1,is0 )
                  nb = ig(1,is02) * ig(1,is02)
                  nt = na * nb
                  call c00(s(ig(5,is0 )),ig(1,is0 ),scr1)
                  call c00(s(ig(5,is02)),ig(1,is02),scr2)
                  call wmix0(w,scr2,nb,scr1,na,nt)
                  equal = .false.
                  if (is0.le.ialfa.and.is02.le.ialfa.or.
     &                is0.gt.ialfa.and.is02.gt.ialfa) equal = .true.
                  call gmix00(ipos,ipos(nt+1),ir,ic,ig,is0,is02,equal)
               else
c.....
                  icase = 8
c.....
c
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 . . . 2 2 2 . . . . . .
c                 . . . 2 2 2 . . . . . .
c                 . . . 2 2 2 . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c
c.....
                  nt = ig(1,is0) * (ig(1,is0)-1) / 2
                  nt = nt * nt
                  call c2222(ig(1,is0),w,s(ig(5,is0)),scr1,scr2)
                  call p2222(ipos,ipos(nt+1),ir(ig(3,is0)),ig(1,is0),
     &                                       ic(ig(4,is0)),ig(2,is0))
c.....
               end if
c.....
            else if (jfix.eq.0) then
c.....
               icase = 9
c.....
c
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . . . . . x x . . .
c              . . . . . . . x x . . .
c              . . . . . . . . . . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               ipar = iparity(ig)
               call c00(s(ig(5,is0)),ig(1,is0),w)
               equal = .false.
               if((is0.le.ialfa.and.ifix.le.nalfa).or.
     &            (is0.gt.ialfa.and.ifix.gt.nalfa)) equal = .true.
               nt = ig(1,is0) * ig(2,is0)
               call g0ff(ipos,ipos(nt+1),ir(ig(3,is0)),ic(ig(4,is0)),
     &                     ig(1,is0),ir(ifix),ic(kfix),equal)
c.....
            else
c.....
               icase = 10
c.....
c
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . . x x . . . . . .
c              . . . . x x . . . . . .
c              . . . . . . . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . . x x
c              . . . . . . . . . . x x
c              . . . . . . . . . . . .
c
c.....
               ipar = iparity(ig)
c.....
c.....         just one integral
c.....
               ir1 = ir(ifix)
               ir2 = ir(jfix)
               ic1 = ic(kfix)
               ic2 = ic(lfix)
               ik  = max(ir1,ic1)*(max(ir1,ic1)-1) / 2 + min(ir1,ic1)
               jl  = max(ir2,ic2)*(max(ir2,ic2)-1) / 2 + min(ir2,ic2)
               ikjl= max(ik ,jl )*(max(ik ,jl )-1) / 2 + min(ik ,jl )
               if ( (ifix.le.nalfa.and.jfix.le.nalfa).or.
     &              (ifix.gt.nalfa.and.jfix.gt.nalfa)   ) then
                  il=max(ir1,ic2)*(max(ir1,ic2)-1) / 2 + min(ir1,ic2)
                  jk=max(ir2,ic1)*(max(ir2,ic1)-1) / 2 + min(ir2,ic1)
                iljk=max(il ,jk )*(max(il ,jk )-1) / 2 + min(il ,jk )
               end if
               ipos(1) = iljk
            end if
c.....
         else if (nrectan.eq.1) then
c.....
            if (is1.eq.is0) then
c.....
               if (ig(1,is0).lt.ig(2,is0)) then
c.....
                  icase = 11
c.....
c
c                    2 2 2 2 . . . . . . . .
c                    2 2 2 2 . . . . . . . .
c                    2 2 2 2 . . . . . . . .
c                    . . . . x x . . . . . .
c                    . . . . x x . . . . . .
c                    . . . . . . . . . . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c
c.....
                  ipar = iparity(ig)
                  nt = ig(2,is0)
                  nt = (nt-1) * nt * (nt-1) / 2
                  call c2kjl(ig(2,is0),w,scr1,scr2,s(ig(5,is0)))
                  call p0kjl(ipos,ipos(nt+1),ir(ifix),ir(ig(3,is0)),
     &                                           ic(ig(4,is0)),ig,is0)
c.....
               else
c.....
                  icase = 12
c.....
c
c                    2 2 2 . . . . . . . . .
c                    2 2 2 . . . . . . . . .
c                    2 2 2 . . . . . . . . .
c                    2 2 2 . . . . . . . . .
c                    . . . x x . . . . . . .
c                    . . . x x . . . . . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c
c.....
                  ipar = iparity(ig)
                  nt   = ig(1,is0)
                  nt   = (nt-1) * nt * (nt-1) / 2
                  call ci2jl(ig(1,is0),w,scr1,scr2,s(ig(5,is0)))
                  call pi0jl(ipos,ipos(nt+1),ic(kfix),ir(ig(3,is0)),
     &                                           ic(ig(4,is0)),ig,is0)
               end if
c.....
            else if ( iabs(ig(1,is1)-ig(2,is1) ).eq.1) then
c.....
               if ( ig(1,is1).gt.ig(2,is1) ) then
c.....
                  if (ifix.eq.0) then
c.....
                     icase = 13
c.....
c
c                    x x x . . . . . . . . .
c                    x x x . . . . . . . . .
c                    x x x . . . . . . . . .
c                    x x x . . . . . . . . .
c                    . . . x x . . . . . . .
c                    . . . x x . . . . . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . . . . 0 0 0
c                    . . . . . . . . . 0 0 0
c                    . . . . . . . . . 0 0 0
c
c.....
                     ipar = iparity(ig)
                     n0 = ig(1,is0) * ig(1,is0)
                     call ci0t(s(ig(5,is1)),ig(1,is1),scr1)
                     call c00(s(ig(5,is0)),ig(1,is0),scr2)
                     call wmix0(w,scr1,ig(1,is1),scr2,n0,nt)
                     equal = .false.
                     if ((kfix.le.nalfa.and.is0.le.ialfa).or.
     &                   (kfix.gt.nalfa.and.is0.gt.ialfa)) equal =.true.
                     call gmix0f(ipos,ipos(nt+1),ir,ic,ig,ic(kfix),
     &                                                    is1,is0,equal)
                  else
c.....
                     icase = 14
c.....
c                    x x x . . . . . . . . .
c                    x x x . . . . . . . . .
c                    x x x . . . . . . . . .
c                    x x x . . . . . . . . .
c                    . . . x x . . . . . . .
c                    . . . x x . . . . . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . . . . . x x
c                    . . . . . . . . . . x x
c                    . . . . . . . . . . . .
c
c.....
                     ipar = iparity(ig)
                     equal = .false.
                     if ((kfix.le.nalfa.and.lfix.le.nalfa) .or.
     &                   (kfix.gt.nalfa.and.lfix.gt.nalfa) )equal=.true.
                     nt = ig(1,is1)
                     call ci0t(s(ig(5,is1)),nt,w)
c.....
c.....               remember that lfix < kfix , mind spin !!!!!!
c.....
                     if (ifix.lt.ig(3,is1)) then
                        icfix1 = lfix
                        icfix2 = kfix
                     else
                        icfix1 = kfix
                        icfix2 = lfix
                     end if
                     call pi000(ipos,ipos(nt+1),ir,ic,ig,is1,ifix,icfix1
     &                                                    ,icfix2,equal)
                  end if
c.....
               else if (kfix.eq.0) then
c.....
                  icase = 15
c.....
c
c                 x x x x . . . . . . . .
c                 x x x x . . . . . . . .
c                 x x x x . . . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . . . . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . 0 0 0
c                 . . . . . . . . . 0 0 0
c                 . . . . . . . . . 0 0 0
c
c.....
                  ipar = iparity(ig)
                  n0 = ig(1,is0) * ig(1,is0)
                  call c0k(s(ig(5,is1)),ig(2,is1),scr1)
                  call c00(s(ig(5,is0)),ig(1,is0),scr2)
                  call wmix0(w,scr1,ig(2,is1),scr2,n0,nt)
                  equal = .false.
                  if ((ifix.le.nalfa.and.is0.le.ialfa).or.
     &                (ifix.gt.nalfa.and.is0.gt.ialfa)) equal =.true.
                  call gmixf0(ipos,ipos(nt+1),ir,ic,ig,ir(ifix),
     &                                                 is1,is0,equal)
c.....
               else
c.....
                  icase = 16
c.....
c
c                 x x x x . . . . . . . .
c                 x x x x . . . . . . . .
c                 x x x x . . . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . . . . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . . x x
c                 . . . . . . . . . . x x
c                 . . . . . . . . . . . .
c
c.....
                  ipar = iparity(ig)
                  equal = .false.
                  if ( (ifix.le.nalfa.and.jfix.le.nalfa) .or.
     &                 (ifix.gt.nalfa.and.jfix.gt.nalfa) ) equal =.true.
                  nt = ig(2,is1)
                  call c0k(s(ig(5,is1)),ig(2,is1),w)
c.....
c.....            jfix < ifix => associate the right one with is1 !!!!
c.....
                  if (kfix.lt.ig(4,is1)) then
                     irfix1 = ifix
                     irfix2 = jfix
                  else
                     irfix1 = jfix
                     irfix2 = ifix
                  end if
                  call p0k00(ipos,ipos(nt+1),ir,ic,ig,is1,irfix1,irfix2,
     &                                                       kfix,equal)
c.....
               end if
c.....
            else
c.....
               if (ig(1,is1).gt.ig(2,is1)) then
c.....
                  icase = 17
c.....
c
c                 x x . . . . . . . . . .
c                 x x . . . . . . . . . .
c                 x x . . . . . . . . . .
c                 x x . . . . . . . . . .
c                 . . . x x . . . . . . .
c                 . . . x x . . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c
c.....
c.....            ipar = 1 - 2 * mod(kfix + lfix + ig(4,is1) + ig(2,is1)
c.....                                           + ig(4,is1) + ig(2,is1)
c.....                                           + 1 , 2) =>
c.....
                  ipar = -iparity(ig)
                  call ci0j0(ig(1,is1),s(ig(5,is1)),w,scr1,scr2)
                  nt = ig(1,is1) * (ig(1,is1)-1) / 2
                  call pa00b(ipos,ipos(nt+1),ir,ic,ig,is1,kfix,lfix)
c.....
               else
c.....
                  icase = 18
c.....
c
c                 x x x x . . . . . . . .
c                 x x x x . . . . . . . .
c                 . . . . . . . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . . . . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c
c.....
c.....            see comment on parity above
c.....
                  ipar = - iparity(ig)
                  call c0k0l(ig(2,is1),s(ig(5,is1)),w,scr1,scr2)
                  nt = ig(2,is1) * (ig(2,is1)-1) / 2
                  call p0k0l(ipos,ipos(nt+1),ir,ic,ig,is1,ifix,jfix)
c.....
               end if
c.....
            end if
c.....
         else if (nrectan.eq.2) then
c.....
            ndelta = ig(1,is1) - ig(2,is1) + ig(1,is2) - ig(2,is2)
c.....
            if ( (ig(3,is1).le.nalfa.and.ig(3,is2).le.nalfa).or.
     &           (ig(3,is1).gt.nalfa.and.ig(3,is2).gt.nalfa)     ) then
c.....
               if ( ndelta.eq.0 ) then
c.....
                  if (ifix.eq.0) then
c.....
                   if (is0.ne.0) then
                    if ((is0.eq.is1).or.(is0.eq.is2)) then
                     if (is0.eq.is2) then
                      is2=is1
                      is1=is0
                     end if
                     if (ig(1,is0).lt.ig(2,is0)) then
c.....
                     icase = 19
c.....
c
c                    2 2 2 2 . . . . . . . .
c                    2 2 2 2 . . . . . . . .
c                    2 2 2 2 . . . . . . . .
c                    . . . . x x . . . . . .
c                    . . . . x x . . . . . .
c                    . . . . x x . . . . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c
c.....
                     ipar = iparity(ig)
                     na = ig(2,is0)
                     na = (na-1) * na * (na-1) / 2
                     call c2kjl(ig(2,is0),scr1,scr2,scr3,s(ig(5,is0)))
                     nb = ig(1,is2)
                     call ci0t(s(ig(5,is2)),ig(1,is2),scr2)
                     call wmix0(w,scr2,nb,scr1,na,nt)
                     call pabbb(ipos,ipos(nt+1),ir,ic,is0,is2,ig)
c.....
                     else
c.....
                     icase = 20
c.....
c
c                    2 2 2 . . . . . . . . .
c                    2 2 2 . . . . . . . . .
c                    2 2 2 . . . . . . . . .
c                    2 2 2 . . . . . . . . .
c                    . . . x x x . . . . . .
c                    . . . x x x . . . . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . x x x . . .
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c                    . . . . . . . . . x x x
c
c.....
                     ipar = iparity(ig)
                     na   = ig(1,is0)
                     na   = (na-1) * na * (na-1) / 2
                     call ci2jl(ig(1,is0),scr1,scr2,scr3,s(ig(5,is0)))
                     nb = ig(2,is2)
                     call c0k(s(ig(5,is2)),ig(2,is2),scr2)
                     call wmix0(w,scr2,nb,scr1,na,nt)
                     call pbabb(ipos,ipos(nt+1),ir,ic,is0,is2,ig)
                    end if
                    else
                        
c.....
                        icase = 21
c
c.....
c.....
c
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . . . . x x x . . .    or   . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . . . . 0 0 0         . . . . . . . . . 0 0 0
c           . . . . . . . . . 0 0 0         . . . . . . . . . 0 0 0
c           . . . . . . . . . 0 0 0         . . . . . . . . . 0 0 0
c
c.....
            if (ig(1,is1).lt.ig(2,is1)) then
               iii = is1
               is1 = is2
               is2 = iii
            end if
            ipar = iparity(ig)
            n0 = ig(1,is0) * ig(1,is0)
            nr = ig(1,is1) * ig(2,is2)
            nt = n0 + nr
            call ci0t(s(ig(5,is1)),ig(1,is1),scr1)
            call c0k(s(ig(5,is2)),ig(2,is2),scr2)
            call wmix0(scr3,scr2,ig(2,is2),scr1,ig(1,is1),n)
            call c00(s(ig(5,is0)),ig(1,is0),scr1)
            call wmix0(w,scr3,n,scr1,n0,nt)
            equal = .false.
            if ((is1.le.ialfa.and.is0.le.ialfa).or.
     &         (is1.gt.ialfa.and.is0.gt.ialfa))equal=.true.
            call pabcd(ipos,ipos(nt+1),ir,ic,ig,is0,is0,is1,
     &                 is2,equal)
            end if
         else
c.....
            icase = 22
c.....
c
c                   x x . . . . . . . . . .     x x x x . . . . . . . .
c                   x x . . . . . . . . . .     x x x x . . . . . . . .
c                   x x . . . . . . . . . .     . . . . x x . . . . . .
c                   x x . . . . . . . . . .     . . . . x x . . . . . .
c                   . . x x x x . . . . . .     . . . . x x . . . . . .
c                   . . x x x x . . . . . .     . . . . x x . . . . . .
c                   . . . . . . x x x . . . or  . . . . . . x x x . . .
c                   . . . . . . x x x . . .     . . . . . . x x x . . .
c                   . . . . . . x x x . . .     . . . . . . x x x . . .
c                   . . . . . . . . . x x x     . . . . . . . . . x x x
c                   . . . . . . . . . x x x     . . . . . . . . . x x x
c                   . . . . . . . . . x x x     . . . . . . . . . x x x
c
c.....
                        if (ig(1,is1).lt.ig(2,is1)) then
                           iii = is1
                           is1 = is2
                           is2 = iii
                        end if
            ipar = 1
c.....
                        na = ig(1,is1)*(ig(1,is1)-1)/2
                        nb = ig(2,is2)*(ig(2,is2)-1)/2
                        nt = na * nb
                        call ci0j0(ig(1,is1),s(ig(5,is1)),w(nt   +1),
     &                                                     scr1,scr2)
                        call c0k0l(ig(2,is2),s(ig(5,is2)),w(nt+na+1),
     &                                                     scr1,scr2)
                        call wmix0(w,w(nt+na+1),nb,w(nt+1),na,nt)
                        call pabab(ipos,ipos(nt+1),ir,ic,ig,is1,is2)
c.....
                     end if
c.....
                  else
c.....
                     icase = 23
c.....
c
c                    x x x . . . . . . . . .   x x x . . . . . . . . .
c                    x x x . . . . . . . . .   x x x . . . . . . . . .
c                    x x x . . . . . . . . .   . . . x x x . . . . . .
c                    x x x . . . . . . . . .   . . . x x x . . . . . .
c                    . . . x x x . . . . . .   . . . x x x . . . . . .
c                    . . . x x x . . . . . .   . . . x x x . . . . . .
c                    . . . . . . x x . . . .   . . . . . . x x . . . .
c                    . . . . . . x x . . . .   . . . . . . x x . . . .
c                    . . . . . . . . . x x x   . . . . . . . . . x x x
c                    . . . . . . . . . x x x   . . . . . . . . . x x x
c                    . . . . . . . . . x x x   . . . . . . . . . x x x
c                    . . . . . . . . . . . .   . . . . . . . . . . . .
c
c.....
                   ipar = iparity(ig)
                   if (ig(1,is1).lt.ig(2,is1)) then
                      iii = is1
                      is1 = is2
                      is2 = iii
                   end if
                   call ci0t(s(ig(5,is1)),ig(1,is1),scr1)
                   call c0k(s(ig(5,is2)),ig(2,is2),scr2)
                   call wmix0(w,scr2,ig(2,is2),scr1,ig(1,is1),nt)
                   equal = .false.
                   if ((is1.le.ialfa.and.ifix.le.nalfa).or.
     &                 (is1.gt.ialfa.and.ifix.gt.nalfa)) equal=.true.
                   call p00ab(ipos,ipos(nt+1),ir,ic,ig,is1,is2,
     &                                              equal,ifix,kfix)
                   if (equal) then
                      if (ifix.lt.ig(3,is1)) ipar=-ipar
                      if (kfix.lt.ig(4,is2)) ipar=-ipar
                   end if
c.....
               end if
c.....
               else if(ndelta.eq.2) then
c.....
                  icase = 24
c.....
c
c                 x x . . . . . . . . . .
c                 x x . . . . . . . . . .
c                 x x . . . . . . . . . .
c                 . . x x . . . . . . . .
c                 . . x x . . . . . . . .
c                 . . x x . . . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c
c.....
                  ipar = iparity(ig)
                  call ci0t(s(ig(5,is1)),ig(1,is1),scr1)
                  call ci0t(s(ig(5,is2)),ig(1,is2),scr2)
                  call wmix0(w,scr2,ig(1,is2),scr1,ig(1,is1),nt)
                  call pa0b0(ipos,ipos(nt+1),ir,ic,ig,is1,is2,lfix,kfix,
     &                                                           .true.)
c.....
               else if(ndelta.eq.-2) then
c.....
                 icase = 25
c.....
c
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 . . . . . . . . . . . .
c                 . . . x x x . . . . . .
c                 . . . x x x . . . . . .
c                 . . . . . . . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c
c.....
                  ipar = iparity(ig)
                  call c0k(s(ig(5,is1)),ig(2,is1),scr1)
                  call c0k(s(ig(5,is2)),ig(2,is2),scr2)
                  call wmix0(w,scr2,ig(2,is2),scr1,ig(2,is1),nt)
                  call p0a0b(ipos,ipos(nt+1),ir,ic,ig,is1,is2,ifix,jfix,
     &                                                           .true.)
c.....
               else if (ndelta.eq.1) then
c.....
                  icase = 26
c.....
c
c                 x x . . . . . . . . . .     x x x . . . . . . . . .
c                 x x . . . . . . . . . .     x x x . . . . . . . . .
c                 x x . . . . . . . . . .     . . . x x . . . . . . .
c                 x x . . . . . . . . . .     . . . x x . . . . . . .
c                 . . x x x . . . . . . .     . . . x x . . . . . . .
c                 . . x x x . . . . . . .     . . . x x . . . . . . .
c                 . . . . . . x x x . . . or  . . . . . . x x x . . .
c                 . . . . . . x x x . . .     . . . . . . x x x . . .
c                 . . . . . . x x x . . .     . . . . . . x x x . . .
c                 . . . . . . . . . x x x     . . . . . . . . . x x x
c                 . . . . . . . . . x x x     . . . . . . . . . x x x
c                 . . . . . . . . . x x x     . . . . . . . . . x x x
c
c.....
             if (ig(1,is1).lt.ig(2,is1)) then
                iii = is1
                is1 = is2
                is2 = iii
             end if
             ipar = -iparity(ig)
             if (kfix.lt.ig(4,is2)) ipar = -ipar
                  call ci0j0(ig(1,is1),s(ig(5,is1)),scr1,scr2,scr3)
                  na = ig(1,is1) * (ig(1,is1)-1) / 2
                  call c0k(s(ig(5,is2)),ig(2,is2),scr2)
                  call wmix0(w,scr2,ig(2,is2),scr1,na,nt)
                  call pa0ab(ipos,ipos(nt+1),ir,ic,ig,is1,is2,kfix)
c.....
               else
c.....
c.....               ndelta = -1
c.....
                  icase = 27
c.....
c
c                 x x . . . . . . . . . .     x x x x . . . . . . . .
c                 x x . . . . . . . . . .     x x x x . . . . . . . .
c                 x x . . . . . . . . . .     . . . . x x . . . . . .
c                 . . x x x x . . . . . .     . . . . x x . . . . . .
c                 . . x x x x . . . . . .     . . . . x x . . . . . .
c                 . . . . . . . . . . . .     . . . . . . . . . . . .
c                 . . . . . . x x x . . . or  . . . . . . x x x . . .
c                 . . . . . . x x x . . .     . . . . . . x x x . . .
c                 . . . . . . x x x . . .     . . . . . . x x x . . .
c                 . . . . . . . . . x x x     . . . . . . . . . x x x
c                 . . . . . . . . . x x x     . . . . . . . . . x x x
c                 . . . . . . . . . x x x     . . . . . . . . . x x x
c
c.....
             if (ig(1,is1).lt.ig(2,is1)) then
                iii = is1
                is1 = is2
                is2 = iii
             end if
             equal=(((ifix.lt.nalfa).and.(ig(3,is1).lt.ialfa)).or.
     &              ((ifix.gt.nalfa).and.(ig(3,is1).gt.ialfa)))
             ipar = -iparity(ig)
             if (equal.and.(ifix.lt.ig(3,is1))) ipar = -ipar
                  call c0k0l(ig(2,is2),s(ig(5,is2)),scr1,scr2,scr3)
                  na = ig(2,is2) * (ig(2,is2)-1) / 2
                  call ci0t(s(ig(5,is1)),ig(1,is1),scr2)
                  call wmix0(w,scr2,ig(1,is1),scr1,na,nt)
                  call p0abb(ipos,ipos(nt+1),ir,ic,ig,is2,is1,ifix)
c.....
               end if
c.....
            else
c.....
               if ( ndelta.eq.0 ) then
c.....
                  if (ig(1,is1).gt.ig(2,is1)) then
c.....
                     isr = is1
                     isc = is2
c.....
                  else
c.....
                     isr = is2
                     isc = is1
c.....
                  end if
c.....
                  icase = 28
c.....
c
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . . . x x x x . .
c                 . . . . . . x x x x . .
c                 . . . . . . x x x x . .
c                 . . . . . . . . . . x x
c                 . . . . . . . . . . x x
c                 . . . . . . . . . . . .
c
c.....
                  ipar = iparity(ig)
                  equal=(((ifix.le.nalfa).and.(ig(3,isr).le.nalfa)).or.
     &                     ((ifix.gt.nalfa).and.(ig(3,isr).gt.ialfa)))
                  if (equal) then
                     if (ifix.lt.ig(3,isr)) ipar=-ipar
                     if (kfix.lt.ig(4,isc)) ipar=-ipar
                  end if
                  call ci0t(s(ig(5,isr)),ig(1,isr),scr1)
                  call c0k(s(ig(5,isc)),ig(2,isc),scr2)
                  call wmix0(w,scr2,ig(2,isc),scr1,ig(1,isr),nt)
                  call pi00l(ipos,ir,ic,ig,isr,isc,ifix,kfix)
c.....
               else if(ndelta.eq.2) then
c.....
c.....            equals icase = 24, but no exchange between blocks
c.....            redundant ??
                  icase = 29
c.....
c
c                 x x . . . . . . . . . .
c                 x x . . . . . . . . . .
c                 x x . . . . . . . . . .
c                 . . . x x x . . . . . .
c                 . . . x x x . . . . . .
c                 . . . x x x . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x .
c                 . . . . . . . . . x x .
c                 . . . . . . . . . x x .
c
c.....
                  ipar = iparity(ig)
                  call ci0t(s(ig(5,is1)),ig(1,is1),scr1)
                  call ci0t(s(ig(5,is2)),ig(1,is2),scr2)
                  call wmix0(w,scr2,ig(1,is2),scr1,ig(1,is1),nt)
c.....
c.....            mind lfix always must be < kfix
c.....
                  call pa0b0(ipos,ipos(nt+1),ir,ic,ig,is1,is2,lfix,kfix,
     &                                                          .false.)
c.....
               else
c.....
                  icase = 30
c.....            cf. case 25
c
c                 x x x . . . . . . . . .
c                 x x x . . . . . . . . .
c                 . . . . . . . . . . . .
c                 . . . x x x . . . . . .
c                 . . . x x x . . . . . .
c                 . . . x x x . . . . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . . . .
c
c.....
                  ipar = iparity(ig)
                  call c0k(s(ig(5,is1)),ig(2,is1),scr1)
                  call c0k(s(ig(5,is2)),ig(2,is2),scr2)
                  call wmix0(w,scr2,ig(2,is2),scr1,ig(2,is1),nt)
c.....
c.....            mind that is1<is2 and jfix<ifix
c.....
                  call p0a0b(ipos,ipos(nt+1),ir,ic,ig,is1,is2,ifix,jfix,
     &                                                          .false.)
c.....
               end if
c.....
            end if
c.....
         else if (nrectan.eq.3) then
c.....
            if (ifix.eq.0.and.kfix.eq.0) then
c.....
               idiff1 = ig(1,is1) - ig(2,is1)
               idiff2 = ig(1,is2) - ig(2,is2)
               idiff3 = ig(1,is3) - ig(2,is3)
               if (iabs(idiff1).eq.2) then
c.....
c
c                 x x . . . . . . . . . .       x x x x . . . . . . . .
c                 x x . . . . . . . . . .       x x x x . . . . . . . .
c                 x x . . . . . . . . . .       . . . . x . . . . . . .
c                 x x . . . . . . . . . .       . . . . x . . . . . . .
c                 . . x x . . . . . . . .       . . . . . x . . . . . .
c                 . . . . x x . . . . . .       . . . . . x . . . . . .
c                 . . . . . . x x x . . .  or   . . . . . . x x x . . .
c                 . . . . . . x x x . . .       . . . . . . x x x . . .
c                 . . . . . . x x x . . .       . . . . . . x x x . . .
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c
c.....
                  isd = is1
                  isa = is2
                  isb = is3
                  id  = idiff1
               else if(iabs(idiff2).eq.2) then
c.....
c
c                 x x . . . . . . . . . .       x . . . . . . . . . . .
c                 . . x x . . . . . . . .       x . . . . . . . . . . .
c                 . . x x . . . . . . . .       . x x x x . . . . . . .
c                 . . x x . . . . . . . .       . x x x x . . . . . . .
c                 . . x x . . . . . . . .       . . . . . x . . . . . .
c                 . . . . x x . . . . . .       . . . . . x . . . . . .
c                 . . . . . . x x x . . .  or   . . . . . . x x x . . .
c                 . . . . . . x x x . . .       . . . . . . x x x . . .
c                 . . . . . . x x x . . .       . . . . . . x x x . . .
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c
c.....
                  isd = is2
                  isa = is1
                  isb = is3
                  id  = idiff2
               else
c.....
c
c                 x x . . . . . . . . . .       x . . . . . . . . . . .
c                 . . x x . . . . . . . .       x . . . . . . . . . . .
c                 . . . . x x . . . . . .       . x . . . . . . . . . .
c                 . . . . x x . . . . . .       . x . . . . . . . . . .
c                 . . . . x x . . . . . .       . . x x x x . . . . . .
c                 . . . . x x . . . . . .       . . x x x x . . . . . .
c                 . . . . . . x x x . . .  or   . . . . . . x x x . . .
c                 . . . . . . x x x . . .       . . . . . . x x x . . .
c                 . . . . . . x x x . . .       . . . . . . x x x . . .
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c                 . . . . . . . . . x x x       . . . . . . . . . x x x
c
c.....
                  isd = is3
                  isa = is1
                  isb = is2
                  id  = idiff3
               end if
c.....
               if (id.gt.0) then
c.....
                  icase = 31
c.....
c
c                 x x . . . . . . . . . .
c                 . . x x . . . . . . . .
c                 . . x x . . . . . . . .
c                 . . x x . . . . . . . .
c                 . . x x . . . . . . . .
c                 . . . . x x . . . . . .
c                 . . . . . . x x x . . . or the other two alternatives
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c
c.....
                  ipar = -iparity(ig)
                  n2 = ig(1,isd) * (ig(1,isd)-1) / 2
                  isc  = n2 * ig(2,isa) * ig(2,isb) + 1
                  call ci0j0(ig(1,isd),s(ig(5,isd)),w(isc),scr1,scr2)
                  call c0k(s(ig(5,isa)),ig(2,isa),scr1)
                  call c0k(s(ig(5,isb)),ig(2,isb),scr2)
                  call wmix0(w(isc+n2),scr2,ig(2,isb),
     &                                   scr1,ig(2,isa),n)
                  call wmix0(w,w(isc+n2),n,w(isc),n2,nt)
                  call pabac(ipos,ipos(nt+1),ir,ic,ig,isd,isa,isb)
c.....
               else
c.....
                  icase = 32
c.....
c
c                 x x x x . . . . . . . .
c                 x x x x . . . . . . . .
c                 . . . . x . . . . . . .
c                 . . . . x . . . . . . .
c                 . . . . . x . . . . . .
c                 . . . . . x . . . . . .
c                 . . . . . . x x x . . . or the other two alternatives
c                 . . . . . . x x x . . .
c                 . . . . . . x x x . . .
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c                 . . . . . . . . . x x x
c
c.....
                  ipar = -iparity(ig)
                  n2 = ig(2,isd) * (ig(2,isd)-1) / 2
                  isc  = n2 * ig(1,isa) * ig(1,isb) + 1
                  call c0k0l(ig(2,isd),s(ig(5,isd)),w(isc),scr1,scr2)
                  call ci0t(s(ig(5,isa)),ig(1,isa),scr1)
                  call ci0t(s(ig(5,isb)),ig(1,isb),scr2)
                  call wmix0(w(isc+n2),scr2,ig(1,isb),
     &                                   scr1,ig(1,isa),n)
                  call wmix0(w,w(isc+n2),n,w(isc),n2,nt)
                  call pabcb(ipos,ipos(nt+1),ir,ic,ig,isd,isa,isb)
c.....
               end if
c.....
            else if (ifix.eq.0) then
c.....
               ipar = iparity(ig)
               if (ig(3,is2).le.nalfa.and.ig(3,is3).gt.nalfa) then
c.....
                  equal = .false.
c.....
                  if (ig(1,is2).lt.ig(2,is2)) then
c.....
                     isr = is1
                     isc = is2
                     iso = is3
c.....
                  else
c.....
                     isr = is2
                     isc = is1
                     iso = is3
c.....
                  end if
c.....
               else if(ig(3,is2).gt.nalfa.and.ig(3,is1).le.nalfa) then
c.....
                  equal = .false.
c.....
                  if (ig(1,is2).lt.ig(2,is2)) then
c.....
                     isr = is3
                     isc = is2
                     iso = is1
c.....
                  else
c.....
                     isr = is2
                     isc = is3
                     iso = is1
c.....
                  end if
c.....
               else
c.....
                  equal = .true.
c.....
                  if (ig(1,is1).lt.ig(2,is1)) then
c.....
                     isr = is2
                     isc = is1
                     iso = is3
c.....
                  else if (ig(1,is2).lt.ig(2,is2)) then
c.....
                     isr = is1
                     isc = is2
                     iso = is3
c.....
                  else
c.....
                     isr = is1
                     isc = is3
                     iso = is2
c.....
                  end if
c.....
               end if
c.....
               icase = 33
c.....
c
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              . . . x . . . . . . . .
c              . . . x . . . . . . . .
c              . . . . x x . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               ipar = iparity(ig)
               if (equal.and.(kfix.lt.ig(4,isc))) ipar = -ipar
               nscr = ig(1,isr) * ig(2,isc) * ig(1,iso) + 1
               call ci0t(s(ig(5,isr)),ig(1,isr),scr1)
               call c0k(s(ig(5,isc)),ig(2,isc),scr2)
               call wmix0(w(nscr),scr2,ig(2,isc),scr1,ig(1,isr),n)
               call ci0t(s(ig(5,iso)),ig(1,iso),scr1)
               call wmix0(w,scr1,ig(1,iso),w(nscr),n,nt)
               call pa0bc(ipos,ipos(nt+1),ir,ic,ig,isr,isc,iso,kfix,
     &                                                         equal)
c.....
            else
c.....
               if (ig(3,is2).le.nalfa.and.ig(3,is3).gt.nalfa) then
c.....
                  equal = .false.
c.....
                  if (ig(1,is1).gt.ig(2,is1)) then
c.....
                     isr = is1
                     isc = is2
                     iso = is3
c.....
                  else
c.....
                     isr = is2
                     isc = is1
                     iso = is3
c.....
                  end if
c.....
               else if(ig(3,is2).gt.nalfa.and.ig(3,is1).le.nalfa) then
c.....
                  equal = .false.
c.....
                  if (ig(1,is2).gt.ig(2,is2)) then
c.....
                     isr = is2
                     isc = is3
                     iso = is1
c.....
                  else
c.....
                     isr = is3
                     isc = is2
                     iso = is1
c.....
                  end if
c.....
               else
c.....
                  equal = .true.
c.....
                  if (ig(1,is1).gt.ig(2,is1)) then
c.....
                     isr = is1
                     isc = is2
                     iso = is3
c.....
                  else if (ig(1,is2).gt.ig(2,is2)) then
c.....
                     isr = is2
                     isc = is1
                     iso = is3
c.....
                  else
c.....
                     isr = is3
                     isc = is1
                     iso = is2
c.....
                  end if
c.....
               end if
c.....
               icase = 34
c.....
c
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . . . . . . . . . .
c              . . . x . . . . . . . .
c              . . . x . . . . . . . .
c              . . . . x x . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               ipar = iparity(ig)
               if (equal.and.(ifix.lt.ig(3,isr))) ipar = -ipar
               nscr = ig(1,isr) * ig(2,isc) * ig(2,iso) + 1
               call ci0t(s(ig(5,isr)),ig(1,isr),scr1)
               call c0k(s(ig(5,isc)),ig(2,isc),scr2)
               call wmix0(w(nscr),scr2,ig(2,isc),scr1,ig(1,isr),n)
               call c0k(s(ig(5,iso)),ig(2,iso),scr1)
               call wmix0(w,scr1,ig(2,iso),w(nscr),n,nt)
               call pab0c(ipos,ipos(nt+1),ir,ic,ig,isr,isc,iso,ifix,
     &                                                         equal)
c.....
            end if
c.....
         else if (nrectan.eq.4) then
c.....
            isra = 0
            isca = 0
            if (ig(1,is4).gt.ig(2,is4)) then
               isra = is4
            else
               isca = is4
            end if
            if (ig(1,is3).gt.ig(2,is3)) then
               isrb = isra
               isra = is3
            else
               iscb = isca
               isca = is3
            end if
            if (ig(1,is2).gt.ig(2,is2)) then
               isrb = isra
               isra = is2
            else
               iscb = isca
               isca = is2
            end if
            if (ig(1,is1).gt.ig(2,is1)) then
               isrb = isra
               isra = is1
            else
               iscb = isca
               isca = is1
            end if
c.....
            icase = 35
c.....
c
c           x x x x . . . . . . . .
c           x x x x . . . . . . . .
c           x x x x . . . . . . . .
c           . . . . x x . . . . . .
c           . . . . x x . . . . . .
c           . . . . x x . . . . . .
c           . . . . . . x x x x . .
c           . . . . . . x x x x . .
c           . . . . . . x x x x . .
c           . . . . . . . . . . x x
c           . . . . . . . . . . x x
c           . . . . . . . . . . x x
c
c.....
            equal = .false.
            ipar = iparity(ig)
            if (ig(3,is1).gt.nalfa.or.ig(3,is4).le.nalfa) equal = .true.
            n  = ig(1,isra) * ig(1,isrb) * ig(2,isca) * ig(2,iscb)
            call ci0t(s(ig(5,isrb)),ig(1,isrb),scr1)
            call c0k(s(ig(5,iscb)),ig(2,iscb),scr2)
            call wmix0(w(n+1),scr2,ig(2,iscb),scr1,ig(1,isrb),nb)
            call ci0t(s(ig(5,isra)),ig(1,isra),scr1)
            call c0k(s(ig(5,isca)),ig(2,isca),scr2)
            call wmix0(w(n+nb+1),scr2,ig(2,isca),scr1,ig(1,isra),na)
            call wmix0(w,w(n+1),nb,w(n+nb+1),na,nt)
            call pabcd(ipos,ipos(nt+1),ir,ic,ig,isra,isca,isrb,iscb,
     &                                                        equal)
c.....
         else
c.....
           write(iwr,*)'########################'
           write(iwr,*)'!!!!!!!!!!!! error !!!!!!!!!!!!!!!!!!!!!!!!!!!!'
           write(iwr,*)'########################'
           write(iwr,*)'unrecognised type of matrix element'
           call sillyy(nelec,nalfa,ig,nblock,ir,ic,supers)
         end if
c.....
      end if
      ntwo = nt - n1
      dprod = dprod * ipar
      call prvc(s,nelec,nelec,s,'o','a')
c
      return
      end

_IF()
c***********************************************************************
      subroutine getp2(g)
c
      implicit REAL (a-h,o-z) , integer   (i-n)
c
c...
c...   get 2-electron density matrix in core for vb
c...     *first stupid symmetry-less version  **
c...     integrals are read from final-mainfile from 4-index
c...     first integral = (00/00) !!!
c...     as this is ao-basis GAMESS must be followed **not tested** not used
c...
       dimension g(*)
c...
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/infoa)
      common/blkin/gin(510),mword,mdumm
      common /posit/ iky(3)
      common /scra/ ijkl4(4,340)
c      common /scra/ ij(2,340),kl(2,340)
INCLUDE(../m4/common/cndx40)
INCLUDE(../m4/common/files)
INCLUDE(../m4/common/atmblk)
c
_IF(linux)
      external fget
_ENDIF 
c     ipos(i,j,k,l) = iky(iky(i)+j) + iky(k) + l  
      ind(i,j) = max(i,j)*(max(i,j)-1)/2+min(i,j)
c
c...  clear integral-array
c
      lenbas = num*(num+1)/2
      call vclr(g,1,lenbas*(lenbas+1)/2+1)
c
c...   start loop over mainfile blocks
c
      do 20113 ifile=1,n11fil
        lb  = n11bl(ifile)
        iunit = n11tap(ifile)
        call search(lb,iunit)
c...
20110   call fget(gin,m,iunit)
c...
        if (m.ne.0) then
c...       process input block
           call unpack(gin(num2e+1),lab816,ijkl4,numlab)
           do 1 loop=1,mword
_IF(littleendian)
            j = ijkl4(1,loop)
            i = ijkl4(2,loop)
            l = ijkl4(3,loop)
            k = ijkl4(4,loop)
_ELSE
c**********************************
            i = ijkl4(1,loop)
            j = ijkl4(2,loop)
            k = ijkl4(3,loop)
            l = ijkl4(4,loop)
_ENDIF
           ij = ind(i,j)
           kl = ind(k,l)
           g(ind(ij,kl))=gin(l)
1          continue
           lb=lb+1
           if (lb.ne.n11lst(ifile)) go to 20110
        end if
20113 continue
      return
      end

c***********************************************************************
      subroutine gete2(g)
c
      implicit REAL (a-h,o-z) , integer   (i-n)
c
c...
c...   get 2-electron integrals in core for vb
c...   for printing ; not ud and not tested ; in vbtran real routines
c...     *first stupid symmetry-less version  **
c...     integrals are read from final-mainfile from 4-index
c...     first integral = (00/00) !!!
c...
INCLUDE(../m4/common/sizes)
       dimension g(*)
c...
INCLUDE(common/tractlt)
INCLUDE(common/ffile)
ckoos      common/blkin/gin(340),ijkl(170),mword
      common/blkin/gin(340),ijkl(340),mword,mdumm
INCLUDE(../m4/common/files)
      common /posit/ iky(3)
      common /scra/ ijkl4(4,340)
c      common /scra/ ij(2,340),kl(2,340)
c
_IF(linux)
      external fget
_ENDIF 
      ipos(i,j,k,l) = iky(iky(i)+j) + iky(k) + l  
c
c...  clear integral-array
c
      call vclr(g,1,lenbas*(lenbas+1)/2+1)
c
c...   start loop over mainfile blocks
c
      do 20113 ifile=1,n2file
        lb = n2blk(ifile)
        iunit = n2tape(ifile)
        call search(lb,iunit)
c...
20110   call fget(gin,m,iunit)
c...
        if (m.ne.0) then
c...       process input block
           call unpack(ijkl,8,ijkl4,mword*4)
c           call unpack(ijkl,8,ij,mword*2)
c           call unpack(ijkl(171),8,kl,mword*2)
           do 1 l=1,mword
1          g(ipos(ijkl4(1,l),ijkl4(2,l),ijkl4(3,l),ijkl4(4,l)))=gin(l)
           lb=lb+1
           if (lb.ne.n2last(ifile)) go to 20110
        end if
20113 continue
_IF(parallel)
      call pg_dgop(71,g,lenbas*(lenbas+1)/2+1,'+')
_ENDIF
      return
      end
_ENDIF

c***********************************************************************
      subroutine mkld1d2(rlag,d1,d2,cicoefs,eelec,
     &                   ir,ic,
     &                   supers,superh,superg,
     &                   nelec,nalfa,nmo,s,q,dtotal,
     &                   iwr)
c
      implicit REAL (a-h,o-z), integer (i-n)
c
c..   this thing calculates non-orthogonal matrix-elements
c..   dumb but robust (for debugging)
c..   non-zero contributions are returned in
c..      lagr :  lagrangian for VBSCF
c..      h    :  corresponding one-electron integrals
c..
INCLUDE(common/turtleparam)
INCLUDE(common/splice)
c.....
c.....for debugging : dets are given by symblo
c.....
c.....
c.....in this routine the matrix-element is calculated ***debug***
c.....
      dimension rlag(*),
     &          s(*),q(*),
     &          d1(*), d2(*),ir(*),ic(*),
     &          supers(*),superh(*),superg(*)
c.....
      logical asing1,asing2,asing3,bsing1,bsing2,bsing3
      dtotal = 0.0d0
      asing1 = .false.
      asing2 = .false.
      asing3 = .false.
      bsing1 = .false.
      bsing2 = .false.
      bsing3 = .false.
      nbeta  = nelec - nalfa
      na     = nalfa*nalfa
c.....
c.....print warning if core option is used while performing optimize or gradient
c.....calculation.
c.....
      if (ncore_i.gt.0) then
         write(iwr,*) '********'
         write(iwr,*) 'Warning! core option is used with optimize',
     &                ' or gradient calculation'
         write(iwr,*) '********'
      end if
c.....
      call makemat(s,nalfa,ir,ic,supers)
      call bio2(s,nalfa,ir,ic,ira,deta,ipa)
      na = nalfa * nalfa
      call makemat(s(na+1),nbeta,ir(nalfa+1),ic(nalfa+1),supers)
      call bio2(s(na+1),nbeta,ir(nalfa+1),ic(nalfa+1),irb,detb,ipb)
      nsing = (nalfa - ira) + (nbeta - irb)
      if (nalfa.eq.0) deta=1
      if (nbeta.eq.0) detb=1
      if (nsing.gt.3) return
      if (nalfa-ira.eq.1) asing1 = .true.
      if (nalfa-ira.eq.2) asing2 = .true.
      if (nalfa-ira.eq.3) asing3 = .true.
      if (nbeta-irb.eq.1) bsing1 = .true.
      if (nbeta-irb.eq.2) bsing2 = .true.
      if (nbeta-irb.eq.3) bsing3 = .true.
      cicoefs = cicoefs * ipa * ipb
c
c.... make room for first and second order cofactors
c
      kw1  = 1
      kw2  = kw1 + nelec*nelec
      kscr = kw2 + (nelec*(nelec+1)/2)**2
c.....
c.....four cases are distinguished : - no singularities
c.....                               - one singularity
c.....                               - two singularities in one block
c.....                               - two singularities in two blocks
c.....                               - three singularities in one block
c.....                               - two singularities in one block 
c.....                                 one singularitie in other block
c.....
      call cofac1(s      ,q(kw1)     ,nalfa,ira,deta)
      call cofac1(s(na+1),q(kw1+na),nbeta,irb,detb)
      if (nsing.lt.2) then
c.....
c.....   here the one-electron contribution per block is calculated
c.....
         if (.not.bsing1) then
           call lagrc1(rlag,d1,cicoefs,eelec,q(kw1),nalfa,
     &                 ir,ic,detb)
         end if
         if (.not.asing1) then
           call lagrc1(rlag,d1,cicoefs,eelec,q(kw1+na),nbeta,
     &                 ir(nalfa+1),ic(nalfa+1),deta)
         end if
      end if
c.....
c.....   two-electron contributions involving one block at a time
c.....   three-electron contributions involving two blocks
c.....
      if (.not.bsing2.and..not.bsing3) then
        call cofac2(nalfa,q(kw2),q(kscr),q(kw1),s,ira,deta)
        if (.not.bsing1) then
          call lagrc2(rlag,d2,cicoefs,superh,q(kw2),nalfa,ir,ic,detb)
        end if
        call lagrc12(rlag,cicoefs,superh,superg,q(kw1+na),q(kw2),
     &               nalfa+1,nbeta,1,nalfa,ir,ic)
      end if
      if (.not.asing2.and..not.asing3) then
        call cofac2(nbeta,q(kw2),q(kscr),q(kw1+na),s(na+1),irb,detb)
        if (.not.asing1) then
          call lagrc2(rlag,d2,cicoefs,superh,q(kw2),nbeta,
     &                ir(nalfa+1),ic(nalfa+1),deta)
        end if
        call lagrc12(rlag,cicoefs,superh,superg,q(kw1),q(kw2),
     &               1,nalfa,nalfa+1,nbeta,ir,ic)
      end if
c.....
c.....   two electron contributions involving the two blocks at a time
c.....
      if (.not.asing2.and..not.bsing2) then
         call lagrc11(rlag,d2,cicoefs,superh,q(kw1),nalfa,nbeta,ir,ic)
      end if
c.....
c.....   three-electron contributions involving one block at a time
c.....
      kscr  = kw2
      ndim = max(nalfa,nbeta)
      kscr2 = kscr + ndim*ndim*ndim
      if (.not.bsing1.and..not.bsing2.and..not.bsing3) then
         call cofac3(rlag,cicoefs,superg,q(kw1),s,nalfa,
     &               ira,deta,detb,ir,ic,q(kscr),q(kscr2))
      end if
      if (.not.asing1.and..not.asing2.and..not.asing3) then
         call cofac3(rlag,cicoefs,superg,q(kw1+na),s(na+1),nbeta,
     &               irb,detb,deta,ir(nalfa+1),ic(nalfa+1),
     &               q(kscr),q(kscr2))
      end if
      if (nsing.eq.0) then
         dtotal = deta * detb  * ipa * ipb
      else
         dtotal = 0.0d0
      end if
      return
      end

c***********************************************************************
      subroutine lagrc1(rlag,d1,cicoefs,eelec,wone,ndim,ir,ic,det)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c.....
c.....in this routine the lagrangian is constructed from the electronic
c.....energy and the first order cofactors. 
c.....
      dimension rlag(*),d1(*),wone(*),ir(*),ic(*)
      ind(i,j) = max(i,j) * (max(i,j)-1)/2 + min(i,j)
      it = 0
      do 20 j=1,ndim
         do 10 i=1,ndim
            it = it + 1
            ipos = ind(ir(i),ic(j))
            rlag(ipos) = rlag(ipos) - wone(it)*cicoefs*det*eelec
            d1(ipos)   = d1(ipos)   + wone(it)*cicoefs*det
10       continue
20    continue
      return
      end

c***********************************************************************
      subroutine lagrc2(rlag,d2,cicoefs,superh,wtwo,ndim,ir,ic,det)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c.....
c.....in this routine the lagrangian is constructed from
c.....the second order cofactors of one block 
c.....
      dimension rlag(*),d2(*),wtwo(*),superh(*),
     &          ir(*),ic(*)
      ind(i,j) = max(i,j) * (max(i,j)-1) / 2 + min(i,j)
      it = 0
      do 40 i=2,ndim
        do 30 j=1,i-1
          do 20 k=2,ndim
            do 10 l=1,k-1
              it = it + 1
              ik = ind( ir(i),ic(k) )
              jl = ind( ir(j),ic(l) )
              il = ind( ir(i),ic(l) )
              jk = ind( ir(j),ic(k) )
              ikjl = ind(ik,jl)
              iljk = ind(il,jk)
              rlag(ik) = rlag(ik) + wtwo(it)*superh(jl)*cicoefs*det
              rlag(jl) = rlag(jl) + wtwo(it)*superh(ik)*cicoefs*det
              rlag(il) = rlag(il) - wtwo(it)*superh(jk)*cicoefs*det
              rlag(jk) = rlag(jk) - wtwo(it)*superh(il)*cicoefs*det
              d2(ikjl) = d2(ikjl) + wtwo(it)*cicoefs*det
              d2(iljk) = d2(iljk) - wtwo(it)*cicoefs*det
10          continue
20        continue
30      continue
40    continue
      return
      end

c***********************************************************************
      subroutine lagrc11(rlag,d2,cicoefs,superh,wone,nalfa,nbeta,ir,ic)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c.....
c.....in this routine the lagrangian is constructed for second
c.....order cofactors constructed out of the first order cofactors
c.....of the alfa and the beta block.
c.....
      dimension rlag(*),d2(*),superh(*),wone(*),ir(*),ic(*)
      ind(i,j) = max(i,j) * (max(i,j)-1) / 2 + min(i,j)
      ita = 0
      do 40 k=1,nalfa
         do 30 i=1,nalfa
            ita = ita + 1
            itb = nalfa*nalfa
            ik = ind( ir(i),ic(k) )
            do 20 l=nalfa+1,nalfa+nbeta
               do 10 j=nalfa+1,nalfa+nbeta
                  itb = itb + 1
                  jl = ind( ir(j),ic(l) )
                  ikjl = ind(ik,jl)
                  rlag(ik) = rlag(ik) + 
     &                       cicoefs*wone(ita)*wone(itb)*superh(jl)
                  rlag(jl) = rlag(jl) + 
     &                       cicoefs*wone(ita)*wone(itb)*superh(ik)
                  d2(ikjl) = d2(ikjl) + wone(ita)*wone(itb)*cicoefs
10             continue
20          continue
30       continue
40    continue
      return
      end

c***********************************************************************
      subroutine lagrc12(rlag,cicoefs,superh,superg,wone,wtwo,
     &                   ib1,n1,ib2,n2,ir,ic)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c.....
c.....in this routine the lagrangian is constructed from
c.....the second order cofactors of one block
c.....the block with first order cofactors has size n1 and starts at in1
c.....the block with second order cofactors has size n2 and starts at in2
c.....
      dimension rlag(*),wone(*),wtwo(*),superh(*),
     &          ir(*),ic(*),superg(*)
      ind(i,j) = max(i,j) * (max(i,j)-1) / 2 + min(i,j)
      ita = 0
      ie1 = ib1+n1-1
      ie2 = ib2+n2-1
      do 60 l=ib1,ie1
        do 50 i=ib1,ie1
          ita = ita + 1
          itb = 0
          do 40 j=ib2+1,ie2
            do 30 k=ib2,j-1
              do 20 m=ib2+1,ie2
                do 10 n=ib2,m-1
                  itb = itb + 1
                  il = ind( ir(i),ic(l) )
                  jm = ind( ir(j),ic(m) )
                  kn = ind( ir(k),ic(n) )
                  jn = ind( ir(j),ic(n) )
                  km = ind( ir(k),ic(m) )
                  iljm = ind(il,jm)
                  ilkn = ind(il,kn)
                  iljn = ind(il,jn)
                  ilkm = ind(il,km)
                  jmkn = ind(jm,kn)
                  jnkm = ind(jn,km)
                  rlag(il) = rlag(il) + cicoefs*
     &                  wone(ita)*wtwo(itb)*(superg(jmkn)-superg(jnkm))
                  rlag(jm) = rlag(jm) + cicoefs*
     &                  wone(ita)*wtwo(itb)*(superg(ilkn))
                  rlag(kn) = rlag(kn) + cicoefs*
     &                  wone(ita)*wtwo(itb)*(superg(iljm))
                  rlag(jn) = rlag(jn) - cicoefs*
     &                  wone(ita)*wtwo(itb)*(superg(ilkm))
                  rlag(km) = rlag(km) - cicoefs*
     &                  wone(ita)*wtwo(itb)*(superg(iljn))
10              continue
20            continue
30          continue
40        continue
50      continue
60    continue
      return
      end

c***********************************************************************
      subroutine cofac3(rlag,cicoefs,superg,wone,s,ndim,irank,
     &                  det,det2,ir,ic,x,q)
c
      implicit REAL (a-h,o-z), integer (i-n)
c
c.....
c.....in this routine the third order cofactors are calculated.
c.....
      dimension x(ndim,ndim,ndim),wone(ndim,ndim),
     &          s(ndim,ndim),rlag(*),superg(*),
     &          ir(*),ic(*),q(*)
c....
c.... The arrays y10,y01 and z use the memory of x. 
c.... Easier and more clear later on
c....
      call cf3xtoy(rlag,cicoefs,superg,wone,s,ndim,irank,
     &             det,det2,ir,ic,x(1,1,2),x(1,1,3),x(1,1,1),q)
      return
      end

c***********************************************************************
      subroutine cf3xtoy(rlag,cicoefs,superg,w1,s,ndim,irank,
     &                   det,det2,ir,ic,y10,y01,z,x)
c
      implicit REAL (a-h,o-z), integer (i-n)
c
      common /ncofac3/nul0,nul1,nul2,nul3,nul4,ndim3
c
c.....
c.....in this routine the third order cofactors are calculated.
c.....
      dimension x(ndim,ndim,ndim),w1(ndim,ndim),s(ndim,ndim),
     &          ir(ndim),ic(ndim),rlag(*),
     &          y01(ndim,ndim),y10(ndim,ndim),z(ndim,ndim)
c....
      if (ndim.lt.3) return
      if (ndim.eq.3) then
c.....
c.....   the third order cofactor of a three-dimensional matrix is 1.
c.....
         w=1.0d0
         ndim3 = ndim3 + 1
         call addw(w,rlag,superg,ir(1),ir(2),ir(3),
     &             ic(1),ic(2),ic(3),cicoefs,det2)
         return
      end if
c.....
      if (irank.lt.ndim-3) then
c.....
c.....   nullity.ge.4
c.....   no non-zero third order cofactors
c.....   already handled by matre2: if (nsing.gt.2) return.
c.....
         nul4 = nul4 + 1
         return
      end if
c.....
c..... nu wordt het spannend
C.....
      if (irank.lt.ndim-2) then
c.....
c.....   nullity.eq.3
c.....
         nul3 = nul3 + 1
         l=ndim-2
         m=ndim-1
         n=ndim
c.....
c.....   calculate last column of second order compound matrix of r,
c.....   element ij,kl is in x(i,j).
c.....   calculate last row    of second order compound matrix of l,
c.....   element kl,ij is in x(j,i).
c.....
c.....   i < j < k
         do 30 k=3,l-1
           do 20 j=2,k-1
             do 10 i=1,j-1
               x(i,j,k) = (s(k,l)*(s(i,m)*s(j,n)-s(i,n)*s(j,m))
     &                  +s(k,m)*(s(i,n)*s(j,l)-s(i,l)*s(j,n))
     &                  +s(k,n)*(s(i,l)*s(j,m)-s(i,m)*s(j,l)))*det
               x(k,j,i) = (s(l,k)*(s(m,i)*s(n,j)-s(n,i)*s(m,j))
     &                  +s(m,k)*(s(n,i)*s(l,j)-s(l,i)*s(n,j))
     &                  +s(n,k)*(s(l,i)*s(m,j)-s(m,i)*s(l,j)))

10           continue
20         continue
30       continue
c.....
        do 50 j=2,l-1
         do 40 i=1,j-1
c.....      i < j < k = l
               x(i,j,l) = (s(i,m)*s(j,n)-s(i,n)*s(j,m)
     &                  +s(l,m)*(s(i,n)*s(j,l)-s(i,l)*s(j,n))
     &                  +s(l,n)*(s(i,l)*s(j,m)-s(i,m)*s(j,l)))*det
               x(l,j,i) = (s(m,i)*s(n,j)-s(n,i)*s(m,j)
     &                  +s(m,l)*(s(n,i)*s(l,j)-s(l,i)*s(n,j))
     &                  +s(n,l)*(s(l,i)*s(m,j)-s(m,i)*s(l,j)))*det
c.....      i < j < k = m
               x(i,j,m) = (s(i,n)*s(j,l)-s(i,l)*s(j,n)
     &                  +s(m,n)*(s(i,l)*s(j,m)-s(i,m)*s(j,l)))*det
               x(m,j,i) = (s(n,i)*s(l,j)-s(l,i)*s(n,j)
     &                  +s(n,m)*(s(l,i)*s(m,j)-s(m,i)*s(l,j)))
c.....      i < j < k = n
               x(i,j,n) = (s(i,l)*s(j,m)-s(i,m)*s(j,l))*det
               x(n,j,i) = (s(l,i)*s(m,j)-s(m,i)*s(l,j))*det
40         continue
50       continue
c.....
         do 60 i=1,j-1
c.....      i < j =l k = m
               x(i,l,m) = (s(i,n)+s(i,l)*(s(l,m)*s(m,n)-s(l,n)
     &                  -s(i,m)*s(m,n)))*det
               x(m,l,i) = (s(n,i)+s(l,i)*(s(m,l)*s(n,m)-s(n,l)
     &                  -s(m,i)*s(n,m)))
c.....      i < j =l k = n
               x(i,l,n) = (s(i,l)*s(l,m)-s(i,m))*det
               x(n,l,i) = (s(l,i)*s(m,l)-s(m,i))
c.....      i < j =m k = n
               x(i,m,n) = s(i,l)*det
               x(n,m,i) = s(l,i)
60       continue
         x(l,m,n) = det
         x(n,m,l) = 1.0d0
c.....
         it=0
         do 120 n = 3,ndim
           do 110 m = 2, n-1
             do 100 l = 1,m-1
               do 90 k = 3,ndim
                 do 80 j = 2,k-1
                   do 70 i = 1,j-1 
                     it=it+1
                     w=x(i,j,k)*x(n,m,l)
                     call addw(w,rlag,superg,ir(n),ir(m),ir(l),
     &                         ic(k),ic(j),ic(i),cicoefs,det2)
70                 continue
80               continue
90             continue
100          continue
110        continue
120      continue
      return
      end if
c.....
      if (irank.eq.ndim-2) then
c.....
c.....   nullity.eq.2
c.....   use factorised cofactor algorithm.
c.....
         nul2 = nul2 + 1
         call vclr(z,1,ndim*ndim)
         call vclr(y10,1,ndim*ndim)
         call vclr(y01,1,ndim*ndim)
c.....
         do 130 i=1,ndim-2
            z(i,i)=1.0d0/s(i,i)
130      continue
         do 150 i=2,ndim-2
            do 140 j=1,i-1
               z(i,j)=z(i,i)*s(i,j)
140         continue
150      continue
c.....
         do 180 j=1,ndim-2
            do 170 i=1,ndim-2
               do 160 k=max(i+1,j),ndim-2
                  z(i,j)=z(i,j)+z(k,j)*s(i,k)
160            continue
170         continue
180      continue
c.....
c..... Make y10 and y10
c.....
         do 200 j=1,ndim-2
           do 190 i=1,ndim-2
             y10(i,j)=s(i,ndim-1)*s(ndim-1,j)
             y01(i,j)=s(i,ndim)*s(ndim,j)
190        continue
200      continue
         do 210 i=1,ndim-2
           y10(i,ndim-1)=s(ndim-1,i)
           y10(ndim-1,i)=s(i,ndim-1)
           y01(i,ndim-1)=s(i,ndim)*s(ndim,ndim-1)
           y01(ndim-1,i)=s(ndim-1,ndim)*s(ndim,i) 
210      continue
         y10(ndim-1,ndim-1)=1.0d0
         y01(ndim,ndim)=1.0d0
         do 220 i=1,ndim-1
           y01(i,ndim)=s(ndim,i)
           y01(ndim,i)=s(i,ndim)
220      continue
c.....
         it=0
         do 280 n=1,ndim
           do 270 m=1,n-1 
             do 260 l=1,m-1
               do 250 k=3,ndim
                 do 240 j=2,k-1
                   do 230 i=1,j-1
                     it=it+1
                     w= (det*(y01(k,n)*y10(j,m)*z(i,l) -
     &                   y01(k,m)*y10(j,n)*z(i,l) -
     &                   y01(j,n)*y10(k,m)*z(i,l) +
     &                   y01(j,m)*y10(k,n)*z(i,l) +
     &                   y01(k,m)*y10(j,l)*z(i,m) -
     &                   y01(k,n)*y10(j,l)*z(i,m) -
     &                   y01(k,l)*y10(j,m)*z(i,m) +
     &                   y01(k,l)*y10(j,n)*z(i,m) -
     &                   y01(j,m)*y10(k,l)*z(i,m) +
     &                   y01(j,n)*y10(k,l)*z(i,m) +
     &                   y01(j,l)*y10(k,m)*z(i,m) -
     &                   y01(j,l)*y10(k,n)*z(i,m) -
     &                   y01(k,n)*y10(i,m)*z(j,l) +
     &                   y01(k,m)*y10(i,n)*z(j,l) +
     &                   y01(i,n)*y10(k,m)*z(j,l) -
     &                   y01(i,m)*y10(k,n)*z(j,l) -
     &                   y01(k,m)*y10(i,l)*z(j,m) +
     &                   y01(k,n)*y10(i,l)*z(j,m) +
     &                   y01(k,l)*y10(i,m)*z(j,m) -
     &                   y01(k,l)*y10(i,n)*z(j,m) +
     &                   y01(i,m)*y10(k,l)*z(j,m) -
     &                   y01(i,n)*y10(k,l)*z(j,m) -
     &                   y01(i,l)*y10(k,m)*z(j,m) +
     &                   y01(i,l)*y10(k,n)*z(j,m) +
     &                   y01(j,n)*y10(i,m)*z(k,l) -
     &                   y01(j,m)*y10(i,n)*z(k,l) -
     &                   y01(i,n)*y10(j,m)*z(k,l) +
     &                   y01(i,m)*y10(j,n)*z(k,l) +
     &                   y01(j,m)*y10(i,l)*z(k,m) -
     &                   y01(j,n)*y10(i,l)*z(k,m) -
     &                   y01(j,l)*y10(i,m)*z(k,m) +
     &                   y01(j,l)*y10(i,n)*z(k,m) -
     &                   y01(i,m)*y10(j,l)*z(k,m) +
     &                   y01(i,n)*y10(j,l)*z(k,m) +
     &                   y01(i,l)*y10(j,m)*z(k,m) -
     &                   y01(i,l)*y10(j,n)*z(k,m)))
                    call addw(w,rlag,superg,ir(l),ir(m),ir(n),
     &                         ic(k),ic(j),ic(i),cicoefs,det2)

230                continue
240              continue
250            continue
260          continue
270        continue
280      continue
         return
      end if
      if (irank.eq.ndim-1) then
c.....
c.....   nullity.eq.1
c.....   use factorised cofactor algorithm.
c.....
         nul1 = nul1 + 1
         call vclr(z,1,ndim*ndim)
c.....
c.....
         do 290 i=1,ndim-1
            z(i,i)=1.0d0/s(i,i)
290      continue
         do 310 i=2,ndim-1
            do 300 j=1,i-1
               z(i,j)=z(i,i)*s(i,j)
300         continue
310      continue
c.....
         do 340 j=1,ndim-1
            do 330 i=1,ndim-1
               do 320 k=max(i+1,j),ndim-1
                  z(i,j)=z(i,j)+z(k,j)*s(i,k)
320            continue
330         continue
340      continue
c.....
         it=0
         do 400 n=3,ndim
           do 390 m=2,n-1 
             do 380 l=1,m-1
               do 370 k=3,ndim
                 do 360 j=2,k-1
                   do 350 i=1,j-1
                     it=it+1
         w=(z(j,m)*z(k,n)-z(j,n)*z(k,m))*w1(l,i)
     &        +(z(i,n)*z(k,m)-z(i,m)*z(k,n))*w1(l,j)
     &        +(z(i,m)*z(j,n)-z(i,n)*z(j,m))*w1(l,k)
     &        +(z(j,n)*z(k,l)-z(j,l)*z(k,n))*w1(m,i)
     &        +(z(i,l)*z(k,n)-z(i,n)*z(k,l))*w1(m,j)
     &        +(z(i,n)*z(j,l)-z(i,l)*z(j,n))*w1(m,k)
     &        +(z(j,l)*z(k,m)-z(j,m)*z(k,l))*w1(n,i)
     &        +(w1(l,j)*w1(m,k)-w1(l,k)*w1(m,j))*w1(n,i)
     &        +(z(i,m)*z(k,l)-z(i,l)*z(k,m))*w1(n,j)
     &        +(w1(l,k)*w1(m,i)-w1(l,i)*w1(m,k))*w1(n,j)
     &        +(z(i,l)*z(j,m)-z(i,m)*z(j,l))*w1(n,k)
     &        -(w1(l,j)*w1(m,i)+w1(l,i)*w1(m,j))*w1(n,k)
                     call addw(w,rlag,superg,ir(l),ir(m),ir(n),
     &                         ic(k),ic(j),ic(i),cicoefs,det2)
350                continue
360              continue
370            continue
380          continue
390        continue
400      continue
         return
      end if
c.....
c.....nullity.eq.0
c.....use jacobi ratio theorem.
c.....
      nul0 = nul0 + 1
      it=0
      do 460 n=3,ndim
        do 450 m=2,n-1
          do 440 l=1,m-1
            do 430 k=3,ndim
              do 420 j=2,k-1
                do 410 i=1,j-1
                  w=w1(l,i)*(w1(m,j)*w1(n,k)-w1(m,k)*w1(n,j)) 
     &             -w1(l,j)*(w1(m,i)*w1(n,k)-w1(m,k)*w1(n,i))
     &             +w1(l,k)*(w1(m,i)*w1(n,j)-w1(m,j)*w1(n,i))
                  w=w/(det*det)
                  call addw(w,rlag,superg,ir(l),ir(m),ir(n),
     &                      ic(i),ic(j),ic(k),cicoefs,det2)
410             continue
420           continue
430         continue
440       continue
450     continue
460   continue
c.....
      return
      end

c***********************************************************************
      subroutine addw(w,rlag,g,i,j,k,l,m,n,cc,det)
c
      implicit REAL (a-h,o-z), integer (i-n)
c
      dimension rlag(*),g(*)
c
      ind(i,j)=max(i,j)*(max(i,j)-1)/2+min(i,j)
c
      c = cc*det
      il = ind(i,l)
      im = ind(i,m)
      in = ind(i,n)
      jl = ind(j,l)
      jm = ind(j,m)
      jn = ind(j,n)
      kl = ind(k,l)
      km = ind(k,m)
      kn = ind(k,n)
      rlag(il)=rlag(il)+c*w*(g(ind(jm,kn))-g(ind(jn,km)))
      rlag(im)=rlag(im)-c*w*(g(ind(jl,kn))-g(ind(jn,kl)))
      rlag(in)=rlag(in)+c*w*(g(ind(jl,km))-g(ind(jm,kl)))
      rlag(jl)=rlag(jl)-c*w*(g(ind(im,kn))-g(ind(in,km)))
      rlag(jm)=rlag(jm)+c*w*(g(ind(il,kn))-g(ind(in,kl)))
      rlag(jn)=rlag(jn)-c*w*(g(ind(il,km))-g(ind(im,kl)))
      rlag(kl)=rlag(kl)+c*w*(g(ind(im,jn))-g(ind(in,jm)))
      rlag(km)=rlag(km)-c*w*(g(ind(il,jn))-g(ind(in,jl)))
      rlag(kn)=rlag(kn)+c*w*(g(ind(il,jm))-g(ind(im,jl)))
      return
      end

c***********************************************************************

      subroutine mkd1vb(coeff,ndet,idet,icp,jcp,nelec,nalfa,dens1,
     &        dmo1,ipos,s,vnat,iortho,northo,nbasis,nmo,
     &        ncore,iprint,mode)
c
      implicit REAL (a-h,o-z), integer (i-n)
c
c...  This subroutine constructs the one-electron density matrix on mo-basis
c...  and on ao-basis. Furthermore it calculates the natural orbitals.
c...  Important parameters:
c...   coeff   - coefficients in psi0 in terms of determinants (input)
c...   ndet    - number of coefficients in coeff; total number of determinants (input)
c...   mode    - determines what should be calculated: (input)
c...             'mo' - calculate density matrix on mo basis only
c...             'ao' - calculate density matrix on mo and ao basis
c...             ('no' - calculate density matrix on mo and ao basis + natural orbitals)
c...     this is taken iver by natorbt
c...   dmo1    - density matrix on mo-basis (output)
c...   dens1   - density matrix on ao-basis (output)
c...   vnat    - natural orbitals (output)
c...  Other parameters:
c...   iortho  - orthogonality info of mo's (generated by sym1) (input)
c...   northo  - number of orthogonality classes (input)
c...   idet    - specification of mo's in determinants (input)
c...   nelec   - number of electrons (input)
c...   nalfa   - number of alfa electrons (input)
c...   nbasis  - number of basis functions (input)
c...   nmo     - number of active mo's (input)
c...   ncore   - number of core mo's (input)
c...   iprint  - print flag (input)
c...   s       - mo metric (memory)
c...   icp,jcp - space for mo's in one determinant; one row of idet (memory)
c...   ipos    - nelec^2 memory block for use in symblo (memory)
c...   qq      - memory - dynamicly allocated, no more q and lword - MARCIN
c
c
c... for dynamic memory allocation debugging purpose, contains IGMEM_ vars.
INCLUDE(../m4/common/gmemdata)
INCLUDE(../m4/common/gmempara)
c
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/vcore)
INCLUDE(common/turtleparam)
      common /blkin/ potnuc,ppx,ppy,ppz,space(505)
INCLUDE(common/scftvb)
INCLUDE(common/ffile)
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/restri)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/timeperiods)
INCLUDE(common/infato)
cINCLUDE(common/tractlt)
      common /tractlt/scri,nprint,ibasis,ncol,nsa,ncurt,lenact,lenbas,
     *                num3,iblkq,ionsec2,nbsort,isecdu
      common /energi/ enatom
INCLUDE(common/brill)
      dimension coeff(ndet),idet(nelec,ndet),icp(nelec),jcp(nelec),
     &          iortho(*),vnat(nbasis,ncore+nmo),s(*),
     &          dens1(*),dmo1(*),ipos(nelec*nelec)
      character*(*) mode
      common /davscf/ eshsst,thrssj,thrssd,maxssc,maxssv,maxssl,iprssd,
     &                alssr,firsss
c
INCLUDE(../m4/common/cndx40)
INCLUDE(../m4/common/atmol3)
INCLUDE(../m4/common/dump3)
INCLUDE(common/vbcri)
c
      ind(i,j) = max(i,j)*(max(i,j)-1)/2 + min(i,j)
      call filiky(iky,maxorb)
c
      ntot = ncol
c
c...  make sure ao density matrix and natural orbitals are zero, just 
c...  in case someone might accidentally call this subroutine in the 'mo'
c...  mode, but in fact needs t
c
      call vclr(dens1,1,lenbas)
      call vclr(vnat,1,nbasis*(ncore+nmo))
c
c...  get mo metric
c
      call rdedx(s,lenact,iblhs,num3)
      call reads(s,lenact,num3)
c

      kdens = igmem_alloc_inf(ntot*(ntot+1)/2,'vbdens.m','mkd1vb',
     &                        'kdens',IGMEM_DEBUG)
      kig   = igmem_alloc_inf(10*nmo+5,'vbdens.m','mkd1vb','kig',
     &                        IGMEM_DEBUG)
c
c...  initialise ig 1 to 5
c
      call igini(Q(kig))
c

      kw    = igmem_alloc_inf(nelec*nelec,'vbdens.m','mkd1vb','kw',
     &                        IGMEM_DEBUG)
      ks    = igmem_alloc_inf(nelec*nelec,'vbdens.m','mkd1vb','ks',
     &                        IGMEM_DEBUG)
c      kscr1 = igmem_alloc_inf(nelec*nelec,'vbdens.m','mkd1vb','kscr1',
c     &                        IGMEM_DEBUG)
      kscr1 = igmem_alloc_inf(nmo*nmo,'vbdens.m','mkd1vb','kscr1',
     &                        IGMEM_DEBUG)
      kscr2 = igmem_alloc_inf(nelec*nelec,'vbdens.m','mkd1vb','kscr2',
     &                        IGMEM_DEBUG)

      call vclr(Q(kdens),1,lenact)
      north = min(northo,nmo)
c
c...  construct one-electron density matrix
c
      do 40 i=1,ndet
         do 30 j=1,i
            call icopy(nelec,idet(1,i),1,icp,1)
            call icopy(nelec,idet(1,j),1,jcp,1)
            call symblo(icp,jcp,nelec,nalfa,iortho,north,s,
     &      ipos,dprod,nbody,Q(kig+5),Q(ks))
            dprod = dprod * coeff(i) * coeff(j)
            if (i.ne.j) dprod = dprod * 2
            call weigh1(Q(kw),ipos,Q(kig+5),nbody,icp,jcp,
     &                  Q(ks),
     &      Q(kscr1),Q(kscr2),nelec,nalfa,dprod,na,n1)
            do 10 k=1,na
               Q(kdens +ipos(k)-1) = Q(kdens +ipos(k)-1)+
     &         Q(kw+k-1)*dprod
10          continue
            do 20 k=na+1,n1
               Q(kdens +ipos(k)-1) = Q(kdens +ipos(k)-1)+
     &         Q(kw+k-1)*dprod
20          continue
30       continue
40    continue
c
      do i=1,lenact
        dmo1(i)=Q(kdens+i-1)
      enddo
c
      if (iprins.gt.1000.or.iprint.gt.1000) then
         write(iwr,70)
70       format(/,' one-electron density matrix in mo basis :')
         call tripri(dmo1,nmo)
      end if
c
c...  Following part transforms 1-electron density matrix
c...  from mo basis to ao basis
c
      if (mode.eq.'ao') then
         do 60 i=2,nmo
            do 50 j=1,i-1
               Q(kdens +i*(i-1)/2+j-1) = 
     x         Q(kdens +i*(i-1)/2+j-1)/2
50          continue
60       continue
c
c...  transform density matrix (covariant tensor) step 1
c...  not yet the transformation to the orthogonal basis
c
         call trtrtr(s,Q(kdens),dens1,nmo,Q(kscr1))
c
         ktran = igmem_alloc_inf(nmo*nmo,'vbdens.m','mkd1vb','ktran',
     &                           IGMEM_DEBUG)
         ke    = igmem_alloc_inf(nmo,'vbdens.m','mkd1vb','ke',
     &                           IGMEM_DEBUG)
         kdeno = igmem_alloc_inf(nmo*(nmo+1)/2,'vbdens.m','mkd1vb',
     &                           'kdeno',IGMEM_DEBUG)
         ktra2 = igmem_alloc_inf(nmo*nmo,'vbdens.m','mkd1vb','ktra2',
     &                           IGMEM_DEBUG)
         kscr  = igmem_alloc_inf(2*(nmo*nmo),'vbdens.m','mkd1vb','kscr',
     &                           IGMEM_DEBUG)

c
c...  save metric in case schmidt does not work
c
         call fmove(s,Q(kscr),lenact)
         ntroub = 0
80       if (ntroub.ne.0) call fmove(Q(kscr),s,lenact)
c
c...  determine transformation matrix
c..   i.e. orthogonalise the mo's
c
         call schmidt(s,Q(ktran),nmo,itroub)
c
         if (itroub.ne.0) then
            ntroub = ntroub + 1
            if ( ntroub .eq. 1 ) write(iwr,90)
90          format(//,' *************** warning ****************',/,
     &                '  vbscf-mo metric contains dependencies!!',/,
     &                ' ****************************************')
            if (ntroub.eq.nmo)
     &      call vberr('1-electron density matrix is empty ?')
            do 100 i=1,nmo
               Q( kscr+ind(i,itroub)-1 ) = 0.0d0
               dens1( ind(i,itroub) ) = 0.0d0
100         continue
            Q( kscr+ind(itroub,itroub)-1 ) = 1.0d0
            goto 80
         end if
c
         if (ntroub.ne.0) then 
           write(iwr,110) ntroub
           write(iwr,*) ' '
         end if
110      format(/,' there seem to be ',i2,' superfluous orbitals in',
     &         ' this wavefunction')
      call fmove(Q(kscr),s,lenact)
      call gmem_free_inf(kscr,'vbdens.m','mkd1vb',
     &                   'kscr')
c
c...  transform density matrix step 2
c...  qq(kdeno) now has the density matrix in the orthogonal basis
c
         kscr  = igmem_alloc_inf(2*(nmo*nmo),'vbdens.m','mkd1vb','kscr',
     &                           IGMEM_DEBUG)
         call mult11(dens1,Q(kdeno),Q(kscr),nmo,nmo,
     &               Q(ktran),Q(ktra2))
c
c...  diagonalise deno using the orthogonalised mo's as "unit-matrix"
c
         call jacobt(Q(kdeno),iky,nmo,Q(ktran),nmo,
     &               Q(ke),1,3,crilow,Q(kscr))
         call gmem_free_inf(kscr,'vbdens.m','mkd1vb',
     &                      'kscr')
         call gmem_free_inf(ktra2,'vbdens.m','mkd1vb','ktra2')
         call gmem_free_inf(kdeno,'vbdens.m','mkd1vb','kdeno')
c
c...  qq(ktran) now contains the natural orbitals in the basis of the
c...  occupied orbitals (i.e. the final orbitals)
c
         kvec = igmem_alloc_inf(ntot*nbasis,'vbdens.m','mkd1vb',
     &                          'kvec',IGMEM_DEBUG)
         call vclr(Q(kvec),1,ntot*nbasis)
c
c...  core orbitals are in front
c
c...  get last vectors from 33
c
_IF(atmol)
         rewind 33
         if (nscf.gt.0) then
c...     read some old info first
            read(33) ndum,(Q(ij),ij=kvec,kvec+ndum-1)
            read(33) nb,na,(Q(ij),ij=kvec,kvec+nb*na-1)
         end if
         read(33) nb,na,(Q(ij),ij=kvec,kvec+nb*na-1)
_ELSE
         kvb7_transvb = kscra7vb('kvb7_transvb',(ncore+nsa)*nbasis,
     #                           'r','r')
         call rdedx(Q(kvec),(ncore+nsa)*nbasis,kvb7_transvb,num8)
_ENDIF

c...  kvec should start at the mo position
c...  transform the natural orbitals to the basis of ao's
c
c...  using kvec + ncore*nbasis instead kvec2 (marcin)
c
         call vclr(vnat(1,ncore+1),1,nbasis*nmo)
         call mxmb(Q(kvec + ncore*nbasis),1,nbasis,
     &             Q(ktran),1,nmo,vnat(1,ncore+1),1,
     &             nbasis,nbasis,nmo,nmo)
c
c...  move core orbitals before the natural orbitals (for dump)
c
         call fmove(Q(kvec),vnat(1,1),nbasis*ncore)
c
c...  the natural orbitals that have occ=2 sometimes look a bit weird
c...  e.g. they may not be symmetry adapted. this is caused by jacobi
c...  via thrssj and doesn't alter the properties that are calculated
c...  you may however consider a canonicalisation to restore symmetry
c...  in case of localised orbitals this is perhaps the only solution
c
         if (iprins.gt.1000.or.iprint.gt.1000) then
            write(iwr,120)
120         format(/,' natural orbitals :')
            call prvc(vnat(1,ncore+1),nmo,nbasis,Q(ke),'v','l')
         end if
c
c...  construct mo density matrix
c
         nn = ntot*(ntot+1)/2 - lenact
         call vclr(Q(kdens+lenact),1,nn)
c
c...  the frozen-core density matrix is somewhat boring
c
         do 130 i=nmo+1,nmo+ncore
            Q(kdens+i*(i+1)/2-1) = 2.0d0
130      continue
c
c...  dump the natural orbitals if requested
c
c     if (dumpnat) call putqq(vnat,nbasis,ntot)
         call putqnatorb(vnat,Q(ke),Q(ke),nbasis,
     &                   nbasis,mouta)
c
c...  vnat is scratch now
c...  interchange core and active orbitals (active in front)
c...  this must be done since the density matrix is made that way
c
         ktmp1 = igmem_alloc_inf(ntot*nbasis,'vbdens.m','mkd1vb','ktmp1'
     &                           ,IGMEM_DEBUG)
         ktmp2 = igmem_alloc_inf(nbasis*nmo,'vbdens.m','mkd1vb','ktmp2',
     &                           IGMEM_DEBUG)
c
c...  ktmp1 and ktmp2 - new vectors, dynamicly allocated, to resolve somehow
c...  klast+nbasis*ncore and klast mem. pointers/vectors (marcin)
c
         call fmove(Q(kvec),Q(ktmp1),nbasis*ncore)
         call fmove(Q(kvec+ncore*nbasis),Q(ktmp2),
     &              nbasis*nmo)
         call fmove(Q(ktmp2),Q(kvec),nbasis*nmo)
         call fmove(Q(ktmp1),Q(kvec+nbasis*nmo),
     &              nbasis*ncore)
         call gmem_free_inf(ktmp2,'vbdens.m','mkd1vb','ktmp2')
         call gmem_free_inf(ktmp1,'vbdens.m','mkd1vb','ktmp1')

         kdag = igmem_alloc_inf(ntot*nbasis,'vbdens.m','mkd1vb','kdag',
     &                          IGMEM_DEBUG)
         kscr = igmem_alloc_inf(nbasis*ntot + nbasis*nbasis,'vbdens.m',
     &                          'mkd1vb','kscr',IGMEM_DEBUG)
         call dagger(nbasis,ntot,Q(kvec),nbasis,
     &               Q(kdag),ntot)
         call mult11(Q(kdens),dens1,Q(kscr),nbasis,ntot,
     &               Q(kdag),Q(kvec))

c
c...  dens1 now contains the density matrix on ao basis
c...  qq(kspi) is difference between the alpha and beta density matrix
c
         if (iprins.gt.1000.or.iprint.gt.1000) then
            write(iwr,160)
160         format(/,' one-electron density matrix in ao basis :')
            call tripri(dens1,nbasis)
         end if
c
c...  store ao density matrix on disk (for convergence criterium or as
c...  basis for the fock matrix, that might be built)
c
c...  lenbas dimension too small, changed to triangle dimension of nbasis (marcin)
c
         nn = nbasis * (nbasis + 1) /2
         kvb7_dn = kscra7vb('kvb7_dn',nn,'r','n')
         if (kvb7_dn.lt.0) then
c...  write new density matrix to disk
            kvb7_dn = kscra7vb('kvb7_dn',nn,'r','w')
            call wrt3(dens1,nn,kvb7_dn,num8)
c...  write zeroes to "old" density matrix
            call vclr(Q(kscr),1,nn)
            kvb7_do = kscra7vb('kvb7_do',nn,'r','w')
            call wrt3(Q(kscr),nn,kvb7_do,num8)
         else
c...  make "new" density "old"
            flip = flip_scra7vb('kvb7_dn','kvb7_do')
c...  write new density to disk
            kvb7_dn = kscra7vb('kvb7_dn',nn,'r','w')
            call wrt3(dens1,nn,kvb7_dn,num8)
         endif
         call wrt3(dens1,nn,ibl3pa,idaf)
c
ccc      call gmem_free_set_inf(kdens,kscr)
         call gmem_free_inf(kscr,'vbdens.m','mkd1vb','kscr')
         call gmem_free_inf(kdag,'vbdens.m','mkd1vb','kdag')
         call gmem_free_inf(kvec,'vbdens.m','mkd1vb','kvec')
         call gmem_free_inf(ke,'vbdens.m','mkd1vb','ke')
         call gmem_free_inf(ktran,'vbdens.m','mkd1vb','ktran')
      end if
c
      call gmem_free_inf(kscr2,'vbdens.m','mkd1vb','kscr2')
      call gmem_free_inf(kscr1,'vbdens.m','mkd1vb','kscr1')
      call gmem_free_inf(ks,'vbdens.m','mkd1vb','ks')
      call gmem_free_inf(kw,'vbdens.m','mkd1vb','kw')
      call gmem_free_inf(kig,'vbdens.m','mkd1vb','kig')
      call gmem_free_inf(kdens,'vbdens.m','mkd1vb','kdens')

      return
      end
c***********************************************************************
      subroutine weigh1(w,ipos,ig,nblock,ir,ic,s,scr1,scr2,nelec,nalfa,
     &                  dprod,na,n1)
c
      implicit REAL (a-h,o-z), integer (i-n)
c
c.....
c.....this routine calculates the weight-factors for the one-electron
c.....integrals. useful for determining the one-electron density matrix
c.....
INCLUDE(common/vblimit)
c
      dimension w(nelec*nelec),ipos(nelec*nelec),ig(5,*),ir(nelec),
     &          ic(nelec),scr1(nelec*nelec),scr2(nelec*nelec),
     &          s(nelec*nelec)
      n1 = 0
      na = 0
      if (nsing.eq.0) then
c.....
         icase = 1
c.....
c
c        x x x . . . . . . . . .
c        x x x . . . . . . . . .
c        x x x . . . . . . . . .
c        . . . x x x . . . . . .
c        . . . x x x . . . . . .
c        . . . x x x . . . . . .
c        . . . . . . x x x . . .
c        . . . . . . x x x . . .
c        . . . . . . x x x . . .
c        . . . . . . . . . x x x
c        . . . . . . . . . x x x
c        . . . . . . . . . x x x
c
c.....
c.....   no singularities, therefore a straightforward calculation
c.....
c.....   one-electron contribution per block
c.....
         do 10 i=1,nblock
            if (i.le.ialfa) na = na + ig(1,i)*ig(1,i)
            call cik( s(ig(5,i)), w(ig(5,i)), scr1,scr2,ig(1,i))
10       continue
         nt = ig(5,nblock) + ig(1,nblock) * ig(1,nblock)
         n1 = nt - 1
c.....
c.....   now determine integral addresses
c.....
         call pik(ipos,ir,ic,ig,nblock)
c.....
      else if (nsing.eq.1) then
c.....
         if (nrectan.eq.0) then
c.....
            if (ifix.eq.0) then
c.....
               icase = 2
c.....
c
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               call c00( s(ig(5,is0)),ig(1,is0),w )
               n1 = ig(1,is0) * ig(1,is0)
               if (is0.le.ialfa) na = n1
               call p00( ipos,ir(ig(3,is0)),ic(ig(4,is0)),ig(1,is0) )
c.....
            else
c.....
               icase = 3
c.....
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . . . . . . . . . .
c              . . . . x x . . . . . .
c              . . . . x x . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
c.....         for one-electron part just one integral
c.....
               ipar    = 1 - 2*mod( ifix + kfix , 2 )
               dprod   = dprod * ipar
               irf     = ir(ifix)
               icf     = ic(kfix)
               ipos(1) = max(irf,icf)*(max(irf,icf)-1)/2+min(irf,icf)
               w(1)    = 1.0d0
               n1      = 1
               if (ifix.le.nalfa) na = 1
            end if
c.....
         else if(nrectan.eq.1) then
c.....
            if (ifix.ne.0) then
c.....
               icase = 4
c.....
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . x x x . . . . . .
c              . . . x x x . . . . . .
c              . . . x x x . . . . . .
c              . . . . . . . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
               ipar = 1 - 2 * mod(ifix + ig(3,is1) + ig(1,is1) ,2)
               if (ifix.lt.ig(3,is1)) ipar = -ipar
               dprod = dprod * ipar
c.....
c.....         one electron part involves those choices of k that make
c.....         the singular block become square
c.....
               call c0k( s(ig(5,is1)),ig(2,is1),w )
               n1 = ig(2,is1)
               if (is1.le.ialfa) na = n1
               call p0k( ipos,ir(ifix),ic(ig(4,is1)),ig(2,is1) )
c.....
            else
c.....
               icase = 5
c.....
c
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              . . x x x . . . . . . .
c              . . x x x . . . . . . .
c              . . x x x . . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               ipar = 1 - 2 * mod(kfix + ig(4,is1) + ig(2,is1) ,2)
               if (kfix.lt.ig(4,is1)) ipar = -ipar
               dprod = dprod * ipar
c.....
c.....         one electron part involves those choices of i that make
c.....         the singular block become square
c.....
               call ci0t( s(ig(5,is1)),ig(1,is1),w )
               n1 = ig(1,is1)
               if (is1.le.ialfa) na = n1
               call pi0( ipos,ir(ig(3,is1)),ig(1,is1),ic(kfix))
c.....
            end if
c.....
         else
c.....
c.....      as far as the singly singular cases are concerned the only
c.....      possibilty left is two rectangular blocks. make sure is1
c.....      always refers to the one that has more rows than columns
c.....
c
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . . . . x x x . . .    or   . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c
c.....
            icase = 6
c.....
            if (ig(1,is1).lt.ig(2,is1)) then
               ipar = 1 - 2*mod( ig(1,is2) * ( ig(3,is2) + ig(3,is1)+
     &                                                     ig(1,is1) )
     &                          +ig(2,is2) * ( ig(4,is2) + ig(4,is1)+
     &                                         ig(2,is2)            ),2)
               iii = is1
               is1 = is2
               is2 = iii
            else
               ipar = 1 - 2*mod( ig(1,is2) * ( ig(3,is2) + ig(3,is1)+
     &                                         ig(1,is2)             )
     &                          +ig(2,is2) * ( ig(4,is2) + ig(4,is1)+
     &                                                     ig(2,is1)),2)
            end if
            dprod = dprod * ipar
c.....
c.....      one electron part
c.....
            n1 = ig(1,is1) * ig(2,is2)
            if (is1.le.ialfa) na = n1
            iscr = n1 + 1
            call ci0t(s(ig(5,is1)),ig(1,is1),w(iscr)       )
            call c0k(s(ig(5,is2)),ig(2,is2),w(iscr+ig(1,is1)))
            call wmix0(w,w(iscr+ig(1,is1)),ig(2,is2),
     &                        w(iscr)       ,ig(1,is1),n1)
            call pab(ipos,ir(ig(3,is1)),ig(1,is1),
     &                    ic(ig(4,is2)),ig(2,is2))
c.....
         end if
      end if
      return
      end
