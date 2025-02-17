      SUBROUTINE EXTGRAD(ieps,xscm)
C-----
C      Driver for calculation of (D)RF 
C      gradients at external charges
C-----
      IMPLICIT REAL (A-H,O-Z)
C
      dimension xscm(*)
C
C-----  Common blocks
C
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
INCLUDE(comdrf/commonrf)
INCLUDE(comdrf/rfgrad)
C
C-----  BEGIN
C
C-----  Electrostatic contribution
C
C
C-----  Contribution from the quantum system
C
C-----  Contribution from the rest of the
C       classical system
C
C
C-----  BEGIN
C
C
C-----  Set DA-record numbers for reading RF contribution and matrices
C
      ILCL = 21
C
      IF (IEPS .EQ. 0) THEN
        ILWT = 26
        ILVR = 28
        ILLUR = 43
        ILINDX = 44
        ILIJ = 56
      ELSE
        ILWT = 30
        ILVR = 32
        ILLUR = 47
        ILINDX = 48
        ILIJ = 57
      ENDIF
C
      IF (MCUPDT) THEN
        ILWT = ILWT + 1
        ILVR = ILVR + 1
        ILCL = 91
      ENDIF
c  NOT YET IMPLEMENTED
C
C-----  Calculate Mulliken charges and dipoles and Dipole Preserving
C       charges if either is required for the analysis
C
c     IF (((IFLDIN .LE. 2) .OR. (IFLDOUT .LE. 2))
c    1    .AND. (IEPS .EQ. 0)) THEN
C 1-----
c       IF (NODPE .EQ. 1) THEN
C   2-----
c         ILMC = 121
c         ILMD = 122
c         ILDC = 124
c         CALL DPPOP(xscm)
c       ELSE
c         ILMC = 126
c         ILMD = 127
c         ILDC = 129
c         CALL DPPOPE(xscm)
c   2-----
c       ENDIF
C 1-----
c     ENDIF
C
C-----  Set memory partitioning
C
C
      ixd = igmem_alloc(nchd)
      ixdb = igmem_alloc(nchd)
      ixv = igmem_alloc(num*num)
      ixdh = igmem_alloc(nchd)
c
c-----  Read density
c
      CALL DENSRD(XSCM(IXD),XSCM(IXDb),XSCM(IXDh))
      call gmem_free(ixdh)
c
c-----  Read overlap and first moment integrals
c
      ixol = igmem_alloc(nchd)
      ixdx = igmem_alloc(nchd)
      ixdy = igmem_alloc(nchd)
      ixdz = igmem_alloc(nchd)
      CALL DAREAD(IDAFh,IODA,XSCM(IXOL),NCHD,12)
      CALL DAREAD(IDAFh,IODA,XSCM(IXDX),NCHD,53)
      CALL DAREAD(IDAFh,IODA,XSCM(IXDY),NCHD,54)
      CALL DAREAD(IDAFh,IODA,XSCM(IXDZ),NCHD,55)
C
C-----  Read expansion centres
C
      ixexp = igmem_alloc(3*nexp)
      CALL DAREAD(IDAFDRF,IODADRF,XSCM(IXEXP),3*NEXP,1)
C
      IF (FIELD(5:) .NE. ' ') THEN
C 1-----
        ixvr = igmem_alloc(nwtr*nwtc)
        ixdipi = igmem_alloc(ndim)
        ixr = igmem_alloc(ndim*ndim)
        ixi = igmem_alloc(ndim)
        CALL DAREAD(IDAFDRF,IODADRF,XSCM(IXVR),NWTR*NWTC,ILVR)
        CALL DAREAD(IDAFIND,IODAIND,XSCM(IXDIPI),NDIM,INDEX)
        CALL DAREAD(IDAFDRF,IODADRF,XSCM(IXR),NDIM*NDIM,ILLUR)
        CALL DAREAD(IDAFDRF,IODADRF,XSCM(IXI),NDIM,ILINDX)
C  -----
        ixb = igmem_alloc(nchd)
        IF (FIELD(5:) .EQ. 'SCF') THEN
          CALL DAREAD(IDAFDRF,IODADRF,XSCM(IXB),NCHD,ILIJ)
        ENDIF
        ixdfld = igmem_alloc(3*ndim)
        ixdifld = igmem_alloc(3*ndim)
        ixdipd = igmem_alloc(ndim)
        ixdip1 = igmem_alloc(ndim)
        ixdip2 = igmem_alloc(ndim)
        if (gamdrf .ne. 0.0) then
          ixwt = igmem_alloc(nwtr*nwtc)
          CALL DAREAD(IDAFDRF,IODADRF,XSCM(IXwt),NWTR*NWTC,ILwt)
          ixdwt = igmem_alloc(nwtr*nwtc)
          ixdvr = igmem_alloc(nwtr*nwtc)
          ixdwty = igmem_alloc(nwtr*nwtc)
          ixdvry = igmem_alloc(nwtr*nwtc)
          ixdwtz = igmem_alloc(nwtr*nwtc)
          ixdvrz = igmem_alloc(nwtr*nwtc)
          ixomg11 = igmem_alloc(nomga)
          ixomg12 = igmem_alloc(nomga)
          ixomg21 = igmem_alloc(nomga)
          ixomg22 = igmem_alloc(nomga)
          ixomg31 = igmem_alloc(nomga)
          ixomg32 = igmem_alloc(nomga)
          ixomg3 = igmem_alloc(nomga)
          ixdipix = igmem_alloc(nwtc*ndim)
          ixrxx = igmem_alloc(nchd)
          ixryy = igmem_alloc(nchd)
          ixrzz = igmem_alloc(nchd)
          ixrxy = igmem_alloc(nchd)
          ixrxz = igmem_alloc(nchd)
          ixryz = igmem_alloc(nchd)
          CALL DAREAD(IDAFdrf,IODAdrf,XSCM(IXrxx),NCHD,61)
          CALL DAREAD(IDAFdrf,IODAdrf,XSCM(IXryy),NCHD,62)
          CALL DAREAD(IDAFdrf,IODAdrf,XSCM(IXrzz),NCHD,63)
          CALL DAREAD(IDAFdrf,IODAdrf,XSCM(IXrxy),NCHD,64)
          CALL DAREAD(IDAFdrf,IODAdrf,XSCM(IXrxz),NCHD,65)
          CALL DAREAD(IDAFdrf,IODAdrf,XSCM(IXryz),NCHD,66)
          ixomat = igmem_alloc(npol*3*3*3)
        else
        ixwt = igmem_alloc(1)
        ixdwt = igmem_alloc(1)
        ixdvr = igmem_alloc(1)
        ixdwty = igmem_alloc(1)
        ixdvry = igmem_alloc(1)
        ixdwtz = igmem_alloc(1)
        ixdvrz = igmem_alloc(1)
        ixomg11 = igmem_alloc(1)
        ixomg12 = igmem_alloc(1)
        ixomg21 = igmem_alloc(1)
        ixomg22 = igmem_alloc(1)
        ixomg31 = igmem_alloc(1)
        ixomg32 = igmem_alloc(1)
          ixomg3 = igmem_alloc(1)
        ixdipix = igmem_alloc(1)
        ixrxx = igmem_alloc(1)
        ixryy = igmem_alloc(1)
        ixrzz = igmem_alloc(1)
        ixrxy = igmem_alloc(1)
        ixrxz = igmem_alloc(1)
        ixryz = igmem_alloc(1)
        ixomat = igmem_alloc(3*3*3)
        endif
C 1-----
      else
        ixvr = igmem_alloc(1)
        ixdipi = igmem_alloc(1)
        ixr = igmem_alloc(1)
        ixi = igmem_alloc(1)
        ixb = igmem_alloc(1)
        ixdfld = igmem_alloc(1)
        ixdifld = igmem_alloc(1)
        ixdipd = igmem_alloc(1)
        ixdip1 = igmem_alloc(1)
        ixdip2 = igmem_alloc(1)
        ixwt = igmem_alloc(1)
        ixdwt = igmem_alloc(1)
        ixdvr = igmem_alloc(1)
        ixdwty = igmem_alloc(1)
        ixdvry = igmem_alloc(1)
        ixdwtz = igmem_alloc(1)
        ixdvrz = igmem_alloc(1)
        ixomg11 = igmem_alloc(1)
        ixomg12 = igmem_alloc(1)
        ixomg21 = igmem_alloc(1)
        ixomg22 = igmem_alloc(1)
        ixomg31 = igmem_alloc(1)
        ixomg32 = igmem_alloc(1)
          ixomg3 = igmem_alloc(1)
        ixdipix = igmem_alloc(1)
        ixrxx = igmem_alloc(1)
        ixryy = igmem_alloc(1)
        ixrzz = igmem_alloc(1)
        ixrxy = igmem_alloc(1)
        ixrxz = igmem_alloc(1)
        ixryz = igmem_alloc(1)
        ixomat = igmem_alloc(3*3*3)
      ENDIF
C
C-----  Read assignment vector
C
      ixie = igmem_alloc(nchd)
      CALL DAREAD(IDAFDRF,IODADRF,XSCM(IXIE),NCHD,2)
C
      CALL GRAEX(drfde,XSCM(IXDFLD),XSCM(IXDIFLD),
     1     XSCM(IXDIPI),XSCM(IXR),XSCM(IXI),XSCM(IXVR),
     2     XSCM(IXDIPD),XSCM(IXEXP),XSCM(IXIE),XSCM(IXB),
     3     XSCM(IXD),xscm(ixdb),xscm(ixv),
     4     XSCM(IXOL),XSCM(IXDX),XSCM(IXDY),
     4     XSCM(IXDZ),xscm(ixomat),xscm(ixdip1),xscm(ixdip2),
     5     xscm(ixwt),xscm(ixdwt),xscm(ixdvr),
     5     xscm(ixdwty),xscm(ixdvry),xscm(ixdwtz),xscm(ixdvrz),
     6     xscm(ixomg11),xscm(ixomg12),
     6     xscm(ixomg21),xscm(ixomg22),xscm(ixomg31),xscm(ixomg32),
     7     xscm(ixomg3),xscm(ixdipix),
     7     xscm(ixrxx),xscm(ixryy),xscm(ixrzz),
     8     xscm(ixrxy),xscm(ixrxz),xscm(ixryz),
     9     NEXP,NDIM,NXTPTS,NCHD,NWTC,num)
C
      CALL hATOUT(drfde,3,NXTPTS,2,'EXTGRAD')
C
      call gmem_free(ixie)
c
      call gmem_free(ixomat)
      call gmem_free(ixryz)
      call gmem_free(ixrxz)
      call gmem_free(ixrxy)
      call gmem_free(ixrzz)
      call gmem_free(ixryy)
      call gmem_free(ixrxx)
c     
      call gmem_free(ixdipix)
      call gmem_free(ixomg3)
      call gmem_free(ixomg32)
      call gmem_free(ixomg31)
      call gmem_free(ixomg22)
      call gmem_free(ixomg21)
      call gmem_free(ixomg12)
      call gmem_free(ixomg11)
c
      call gmem_free(ixdvrz)
      call gmem_free(ixdwtz)
      call gmem_free(ixdvry)
      call gmem_free(ixdwty)
      call gmem_free(ixdvr)
      call gmem_free(ixdwt)
      call gmem_free(ixwt)
c
      call gmem_free(ixdip2)
      call gmem_free(ixdip1)
      call gmem_free(ixdipd)
      call gmem_free(ixdifld)
      call gmem_free(ixdfld)
c
      call gmem_free(ixb)
      call gmem_free(ixi)
      call gmem_free(ixr)
      call gmem_free(ixdipi)
      call gmem_free(ixvr)
c
      call gmem_free(ixexp)
c
      call gmem_free(ixdz)
      call gmem_free(ixdy)
      call gmem_free(ixdx)
      call gmem_free(ixol)
      call gmem_free(ixv)
      call gmem_free(ixdb)
      call gmem_free(ixd)
C
      RETURN
      END
      SUBROUTINE GRAEX(GRAD,DFLD,DIFLD,
     +           DIPIND,RELAY,INDEX,
     +           VR,DIPINDD,
     +           XEXP,IEXPC,IJBIT,D,db,v,OL,DX,DY,DZ,
     +           diifld,dipin1,dipin2,
     +           wt,dvr,dwt,dwty,dvry,dwtz,dvrz,
     +           omega11,omega12,
     +           omega21,omega22,omega31,omega32,
     +           omega3,dipix,
     +           rxx,ryy,rzz,rxy,rxz,ryz,
     +           NEX,NDIMP,NXTP,NCH,NVR,nu)
C-----
C      (Direct) Reaction Field gradient at 
C      external centres (classical system)
C      due to other classical parts
C-----
      IMPLICIT REAL (A-H,O-Z)
C
      DIMENSION GRAD(3*NXTP)
      DIMENSION DFLD(NDIMP,3), DIFLD(NDIMP,3)
      DIMENSION VR(NDIMP,NVR)
      DIMENSION DIPIND(NDIMP), DIPINDD(NDIMP)
      dimension dipin1(ndimp),dipin2(ndimp)
      DIMENSION RELAY(NDIMP,NDIMP)
      DIMENSION INDEX(NDIMP)
      DIMENSION XEXP(3,NEX)
      DIMENSION IEXPC(NCH), IJBIT(NCH)
      DIMENSION D(NCH),db(nch)
      DIMENSION OL(NCH),DX(NCH),DY(NCH),DZ(NCH)
      dimension diifld(npol,3,3,3)
      dimension wt(ndimp,nvr)
      dimension dwt(ndimp,nvr), dvr(ndimp,nvr)
      dimension dwty(ndimp,nvr), dvry(ndimp,nvr)
      dimension dwtz(ndimp,nvr), dvrz(ndimp,nvr)
      dimension omega11(nwtc,nwtc), omega12(nwtc,nwtc)
      dimension omega21(nwtc,nwtc), omega22(nwtc,nwtc)
      dimension omega31(nwtc,nwtc), omega32(nwtc,nwtc)
      dimension omega3(nwtc,nwtc)
      dimension dipix(nwtc,ndim)
      dimension rxx(nch),ryy(nch),rzz(nch),
     1          rxy(nch),rxz(nch),ryz(nch)
      dimension v(nu,nu)
C
C-----  Common blocks
C
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/ijpair)
INCLUDE(comdrf/bas)
INCLUDE(comdrf/mollab)
c
INCLUDE(comdrf/drfpar)
INCLUDE(../m4/common/drfopt)
INCLUDE(comdrf/extinf)
INCLUDE(comdrf/grinf)
INCLUDE(comdrf/drfamb)
INCLUDE(comdrf/drfexp)
c
INCLUDE(comdrf/opt)
c
INCLUDE(comdrf/drfind)
      common/drfint/j1,jjj,k1,l1,val
c
caleko
INCLUDE(comdrf/alpbet)
INCLUDE(comdrf/scfopt)
c
INCLUDE(comdrf/ihelp)
c
INCLUDE(comdrf/shlint)
INCLUDE(comdrf/scfpar)
c
INCLUDE(comdrf/drfbem)
INCLUDE(comdrf/rad)
c
      DIMENSION PQ(3)
      DIMENSION B(3,3), B2(3,3), POLTEN(3,3)
      dimension b3(3,3), b23(3,3)
      DIMENSION O(3,3)
      DIMENSION GRADT(3), GRADT2(3), GRADT3(3)
      DIMENSION q0(3),DIP(4), DIP2(4), ph1(4)
      CHARACTER*16 NAMEI,NAMEJ
      LOGICAL POLI,POLJ
      dimension rr(4,4)
C
      logical odebug
C
C
      LOGICAL UHF,ROHF,RGVB,ROGVB
      LOGICAL CORE,OPEN,PAIR
C
      REAL NINE
      DATA ZERO, ONE, TWO, three 
     1  /0.0D00, 1.0D00, 2.0D00, 3.0D00/    
      data four, nine, twelve /4.0D00, 9.0D00, 1.2D01/   
      data sixth,fivsix /1.66666666666666d-01,
     1  8.33333333333333d-01/
      data fifth,pt5,pt75,onept5,twopt5 
     1    /2.d-01,5.d-01,7.5d-01,1.5d00,2.5d00/
      data pt25 /2.5d-01/
      DATA REPCUT /1.0D02/
      DATA THRESH /1.D-10/
      data small /1.0d-03/
C
C-----  BEGIN
C
C
C
      UHF = SCFTYP .EQ. 'UHF'
      ROHF = (SCFTYP.EQ. 'RHF') .AND. (NOPSET.GT.0)
      RGVB = SCFTYP .EQ. 'GVB'
      ROGVB = ROHF .OR. RGVB
C
      CORE = NCORB.NE.0
      OPEN = NOPSET.NE.0
      PAIR = NPAIRS.NE.0
C
C-----  Set up mapping of FOCK matrices
C
      IF (ROGVB) THEN
C 1-----
        NONE = 1
        IF (.NOT. CORE) NONE = 0
        IF (CORE) THEN
C   2-----
          DO I = 1, NCORB
            IHLP(I) = 1
          enddo   
C   2-----
        ENDIF
        NOP = 0
C
        IF (OPEN) THEN
C   2-----
          do ISET = 1, NOPSET
C     3-----
            IOP = NOPEN(ISET)
            do I = 1, IOP
              IHLP(NCORB+NOP+I) = NONE + ISET
            enddo   
            NOP = NOP + IOP
C     3-----
          enddo   
C   2-----
        ENDIF
C
C
        IF (PAIR) THEN
C   2-----
          NGEM = 2*NPAIRS
          do IGEM = 1, NGEM
            IHLP(NCORB+NOP+IGEM) = NONE + NOPSET + IGEM
          enddo   
C   2-----
        ENDIF
C
        NORB = NCORB + NOP + 2*NPAIRS
        NCO1 = NCORB + 1
C
C  -----  Get vectors and constuct density
C
        CALL DAREAD(IDAFh,IODA,V,NUM*NUM,15)
        IF (CORE) THEN
C   2-----
          DO I = 1, NUM
C     3-----
            DO J = 1, I
C       4-----
              DUM = ZERO
              DO K = 1, NCORB
                DUM = DUM + V(I,K)*V(J,K)
              enddo
              IJ = IA(I) + J
              DB(IJ) = DUM
C       4-----
            enddo   
C     3-----
          enddo   
C   2-----
        ENDIF
C 1-----
      ENDIF
C
      odebug = .false.
      pseufac = pt75
C
      CALL CLEAR(GRAD,3*NXTPTS)
c
      IMP = 1
      DO I1 = 1, NXTPTS
C 1-----  Loop over all classical points at which
C         gradient is required
C
      valgr = zero
      valgrs = zero
        ZI = CHRG(I1)
        NAMEI = NXCENT(I1)
        IPOL = MPOL(IMP)
        POLI = IPOL .EQ. I1
        alfi = alfext(i1)
        IGRANI = IGRANL(I1)
        IGRAD = (I1-1)*3 + 1
        IINDp = (IMP-1)*3 + 1
C
        IF (FIELD(5:) .NE. ' ') THEN
          CALL CLEAR(DFLD,3*NDIM)
          CALL CLEAR(DIFLD,3*NDIM)
          if (gamdrf .ne. 0.0) then
          CALL CLEAR(DiIFLD,NPOL*3*3*3)
          endif
        ENDIF
C     
        JMP = 1
        DO JJ = 1, NXTPTS
C   2-----
C    -----  Loop over other external points
C
          JPOL = MPOL(JMP)
          POLJ = JPOL .EQ. JJ
          alfj = alfext(jj)
          NAMEJ = NXCENT(JJ)
          IGRANJ = IGRANL(JJ)
          JIND = (JMP-1)*3 + 1
C
          IF (JJ .EQ. I1) GOTO 40
C
C    -----  Exclude interactions between members of the same group
C
c         IF (NAMEI(NGRNAM:) .EQ. NAMEJ(NGRNAM:)) GOTO 40
C
C    -----  Set index for analysis of interactions
C
          INDXEN = IA(MAX(IGRANI,IGRANJ)) + MIN(IGRANI,IGRANJ)
C
          ZJ = CHRG(JJ)
C
C    -----  Distance vector between ii and jj in -PQ-
C
          CALL DISTAB(XPTS(1,JJ),XPTS(1,I1),PQ,DIST)
          DMIND1 = ONE/DIST
          u = ONE
          FACTP = ONE
          FACTF = ONE
          factt = one
          factd = one
C
C    -----  Scale interaction between point charges according to Thole
C           (optional)
C
          IF (MODXZA .NE. 0) THEN
C     3-----
            S = (ALFI*ALFJ)**SIXTH
            u = DIST/S
C
            IF (ITHOLE .EQ. 1) THEN
C       4-----
              IF (u .LE. AFACT) THEN
                AV = u/AFACT
                FACTP = AV**4 - TWO*AV**3 + TWO*AV
                FACTF = FOUR*AV**3 - THREE*AV**4
                factt = av**4
                factd = fifth*av**4
              ENDIF
C       4-----
            ELSE
C       4-----
              AU = AFACT*u
              FACTP = (ONE - (pt5*AU + ONE)*EXP(-AU))
              FACTF = (ONE - (PT5*AU**2 + AU + ONE)*EXP(-AU))
              factt = factf - sixth*au**3*exp(-au)
              factd = factt - (au**4/30.0d0)*exp(-au)
C       4-----
            ENDIF
C     3-----
          ENDIF
C
C    -----  Dipole-dipole interaction tensor in B
C
          DMIN3 = DMIND1**3
          CALL DRFTPQ(PQ,DMIND1,DMIN3,ITHOLe,AFACT,u,B)
          if (odebug) CALL hATOUT(B,3,3,2,'B')
C
          IF ((ZI .NE. ZERO)
     1      .and. (namei(7:(6+ngrnam)) .ne. namej(7:(6+ngrnam)))) THEN
C     3-----
C      -----  Contributions at a charge
C
C      -----  From charge at JJ
C
            IF (ZJ .NE. ZERO)  THEN
C       4-----
              DO K = 1, 3
                GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1)
     1               - PQ(K)*ZI*ZJ*DMIN3*FACTF
              ENDDO
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C       4-----
            ENDIF
C
C      -----  From induced dipole at JJ
C
            IF (POLJ .AND. (FIELD(5:) .NE. ' ')) THEN
C       4-----
              CALL MATVEC(B,DIPIND(JIND),GRADT,3,.FALSE.)
              CALL ADDUPVS(GRAD(IGRAD),GRADT,GRAD(IGRAD),PT5*ZI,3)
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C
C        -----  build super-vector derivative 
C               of inducing field due to II at JJ
C
              DO K = 1, 3
                CALL ADDUPVS(DFLD(JIND,K),B(1,K),DFLD(JIND,K),-ZI,3)
              ENDDO
C       4-----
            ENDIF
C     3-----
          ENDIF
C
          IF (POLI .AND. (FIELD(5:) .NE. ' ')) THEN
C     3-----
C      -----  Contribution due to field derivative of 
C             other charges
C
            IF ((ZJ .NE. ZERO) 
     1      .and. (namei(7:(6+ngrnam)) .ne. namej(7:(6+ngrnam)))) THEN
C       4-----
              CALL MATVEC(B,DIPIND(IINDp),GRADT,3,.FALSE.)
              CALL ADDUPVS(GRAD(IGRAD),GRADT,GRAD(IGRAD),-PT5*ZJ,3)
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C
              DO K = 1, 3
                CALL ADDUPVS(DIFLD(IINDp,K),B(1,K),DIFLD(IINDp,K),ZJ,3)
              ENDDO
C       4-----
            ENDIF
C
            IF (POLJ) THEN
C       4-----
C        -----  Contribution from field derivative at other 
C               induced dipoles and v.v.
C
              DO K = 1, 3
                CALL DRFOPQ(PQ,DMIND1,O,K,ITHOLe,AFACT,u)
                if (odebug) CALL hATOUT(O,3,3,2,'O')
                CALL MATVEC(O,DIPIND(IINDp),GRADT,3,.FALSE.)
                if (odebug) CALL hATOUT(GRADT,3,1,2,'GRADT')
                CALL ADDUPVS(DIFLD(JIND,K),GRADT,DIFLD(JIND,K),ONE,3)
C
C        -----  NOTE: scaled by -1. because O(j;i) = - O(i;j)
C
                CALL MATVEC(O,DIPIND(JIND),GRADT,3,.FALSE.)
                if (odebug) CALL hATOUT(GRADT,3,1,2,'GRADT')
                CALL ADDUPVS(DIFLD(IINDp,K),GRADT,DIFLD(IINDp,K),ONE,3)
                if (gamdrf .ne. 0.0) then
c
c            -----  collect field derivatives 
c
                  call putomat(diifld,o,npol,jj,k)
                endif
              ENDDO
C       4-----
            ENDIF
C
            if (namei(7:(6+ngrnam)) .eq. namej(7:(6+ngrnam))) goto 40
            if (iclintd .eq. 1) then
c       4-----
              if (poli .and. polj) then
c         5-----
c        -----  calculate approximate dispersion between
c               classical entities via slater-kirkwood formula
c
                if ((igrppol .eq. 0) .and.
     1           (namei(1:5) .eq. 'group') .and.
     2           (namej(1:5) .eq. 'group')) goto 25
c
                fsk = sqrt(polar(imp)/vale(imp)) +
     1              sqrt(polar(jmp)/vale(jmp))
c
c        -----  isotropic or non-isotropic dispersion may be used
c
                dmin4 = (dmind1*dmind1)**2
c
                if (isodis .eq. 1) then
c           6-----
c          -----  isotropic polarisabilities
c
                  dmin8 = (dmin4)**2
                  factgd = onept5*factt**2 
     1        + fivsix*(factf*(factd-factt))
     1        - twopt5*factt*factd
                  discon = nine*polar(imp)*polar(jmp)*dmin8*factgd
                  do k = 1, 3
                    grad(igrad+k-1) = grad(igrad+k-1) 
     1                  - pq(k)*discon/fsk
                  enddo
c           6-----
                else
c           6-----
c          -----  non-isotropic polarisabilities
c          -----  calculate interaction tensor bq
c
                  do k = 1, 3
                    call drfopq(pq,dmind1,o,k,ithole,afact,v)
c
c          -----  multiply polarisability tensors: bq = aj bq ai
c
                    call tenmul(o,b,b2,3)
                    call tenmul(b,o,b3,3)
                    if (namei(1:5) .eq. 'group') then
                      call hexpand(grpol(1,imp),polten,3,3)
                    else
                      call mkdiagm(polar(imp),polten,3)
                    endif
                    call addupvs(b2,b3,b23,one,9)
                    call tenmul(b23,polten,b,3)
                    if (namej(1:5) .eq. 'group') then
                      call hexpand(grpol(1,jmp),polten,3,3)
                    else
                      call mkdiagm(polar(jmp),polten,3)
                    endif
                    call tenmul(polten,b,b2,3)
c
c          -----  calculate trace of product tensor bq
c
                    call trace(b2,discon,3)
                    discon = discon / four
                    grad(igrad+k-1) = grad(igrad+k-1) + discon/fsk
                  enddo
c           6-----
                endif
c
  25            continue
c         5-----
              else if (igrppol .eq. 0) then
c         5-----
c           use atom polarizabilities
c
                dmin4 = (dmind1*dmind1)**2
c
                if ((atpol(i1) .ne. zero)
     1      .and. (atpol(jj) .ne. zero)) then
c           6-----
                  fsk = sqrt(atpol(i1)/valat(i1)) +
     1              sqrt(atpol(jj)/valat(jj))
c
c        -----  isotropic or non-isotropic dispersion may be used
c
                  if (isodis .eq. 1) then
c             7-----
c          -----  isotropic polarisabilities
c
                    dmin8 = (dmin4)**2
                    factgd = onept5*factt**2 
     1      + fivsix*(factf*(factd-factt))
     1      - twopt5*factt*factd
                    discon = nine*polar(imp)*polar(jmp)*dmin8*factgd
                    do k = 1, 3
                      grad(igrad+k-1) = grad(igrad+k-1) 
     1         - pq(k)*discon/fsk
                    enddo
c             7-----
                  else
c             7-----
c          -----  non-isotropic polarisabilities
c          -----  calculate interaction tensor bq
c
                    do k = 1, 3
                      call drfopq(pq,dmind1,o,k,ithole,afact,v)
c
c          -----  multiply polarisability tensors: bq = aj bq ai
c
                      call tenmul(o,b,b2,3)
                      call tenmul(b,o,b3,3)
                      call addupvs(b2,b3,b23,one,9)
                      call hexpand(atpolt(1,i1),polten,3,3)
                      call tenmul(b23,polten,b,3)
                      call hexpand(atpolt(1,jj),polten,3,3)
                      call tenmul(polten,b,b2,3)
c
c          -----  calculate trace of product tensor bq
c
                      call trace(b2,discon,3)
                      discon = discon / four
                      grad(igrad+k-1) = grad(igrad+k-1) 
     1                  + discon/fsk
                    enddo
c             7-----
                  endif
c
c           6-----
                endif
c         5-----
              endif
c       4-----
            endif
c     3-----
          endif
c
          IF ((ICLINTR .EQ. 1) .AND. (DIST .LE. REPCUT)) THEN
C     3-----
C      -----  Calculate approximate repulsion
C             between external charge groups, with empirical R12-term
C             from CHARMm
C
            if ((namei(:2) .ne. 'qq') .and.
c    1          (namei(:2) .ne. 'xx') .and.
     2          (namei(:2) .ne. 'e ') .and.
     3          (namei(:2) .ne. ' ') .and.
     4          (namei(:2) .ne. 'gr') .and.
     5          (namej(:2) .ne. 'qq') .and.
c    6          (namej(:2) .ne. 'xx') .and.
     7          (namej(:2) .ne. 'e ') .and.
     8          (namej(:2) .ne. ' ') .and.
     9          (namej(:2) .ne. 'gr')) then
C       4-----
              CALL DRFNVAL(NAMEI,NVALI,ZNUC)
              AOVERNI = SQRT(ALFI/NVALI)
C
              CALL DRFNVAL(NAMEJ,NVALJ,ZNUC)
              AOVERNJ = SQRT(ALFJ/NVALJ)
C
              RI = RADEXT(I1)*RFACT
              RJ = RADEXT(JJ)*RFACT
C
C          -----  Account for H-bonding
C
              if ((ihbond .eq. 1)
     1            .and. (dist .le. hbondl)) then
c         5-----
                if(namej(:2).eq.'h'.and.
     1            (namei(:2).eq.'n'.or.
     2             namei(:2).eq.'o'.or.
     3             namei(:2).eq.'f')) rj=hbondr
                if(namei(:2).eq.'h'.and.
     1            (namej(:2).eq.'n'.or.
     2             namej(:2).eq.'o'.or.
     3             namej(:2).eq.'f')) ri=hbondr
c         5-----
              endif
C
C        -----  Calculate model repulsion
C
              FAC1 = AOVERNI + AOVERNJ
              FAC2 = PT75*ALFI*ALFJ
              FAC3 = (RI+RJ)**6
              FAC4 = TWELVE*DMIND1**14
              DO K = 1, 3
                GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) 
     1          -PQ(K)*FAC2*FAC3*FAC4/FAC1
              ENDDO
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C       4-----
            ENDIF
C     3-----
          ENDIF
C
   40     IF(POLJ) JMP=JMP+1
C   2-----
        ENDDO
C
C  -----  Loop over expansion centres 
C         for contributions from QM system
C         (nuclei and electrons)
C
          if (poli .and. (field(5:) .ne. ' ') .and.
     1       (gamdrf .ne. 0.0)) then
          CALL DWTVRcla(1,i1,XEXP,DWT,DVR,
     1       XSURF,XNORM,AREA,0,0)
          CALL DRFdOMGA(0,RELAY,DWT,VR,
     1    OMEGA11,INDeX,DIPIX)
          CALL DRFdOMGA(0,RELAY,WT,dVR,
     1    OMEGA12,INDeX,DIPIX)
          CALL DWTVRcla(2,i1,XEXP,DWTy,DVRy,
     1       XSURF,XNORM,AREA,0,0)
          CALL DRFdOMGA(0,RELAY,DWTy,VR,
     1    OMEGA21,INDeX,DIPIX)
          CALL DRFdOMGA(0,RELAY,WT,dVRy,
     1    OMEGA22,INDeX,DIPIX)
          CALL DWTVRcla(3,i1,XEXP,DWTz,DVRz,
     1       XSURF,XNORM,AREA,0,0)
          CALL DRFdOMGA(0,RELAY,DWTz,VR,
     1    OMEGA31,INDeX,DIPIX)
          CALL DRFdOMGA(0,RELAY,WT,dVRz,
     1    OMEGA32,INDeX,DIPIX)
          CALL DRFdOMGA(0,RELAY,WT,VR,
     1    OMEGA3,INDeX,DIPIX)
        endif
        DO J = 1, NEXP
C   2-----
C    -----  Exclude ambiguous atom: its interaction with the
C           discrete classical system is treated classically
C
          IF (NAMBPT(J) .NE. 0) GOTO 50
C
          IF (J .LE. NAT) THEN
C     3-----
C      -----  Current expansion centre is at a nucleus
C
            ZJ = CZAN(J)
            NAMEJ(1:8) = ANAM(J)
            ALFJ = ALFAT(J)
C
C      -----  # of  valence electrons
C
            CALL DRFNVAL(NAMEJ,NVALJ,ZNUC)
C
C      -----  Scaling factor for Slater-Kirkwood estimate
C             of dispersion and repulsion energy
C
            IF (ALFJ .NE. ZERO) THEN
              AOVERNJ= SQRT(ALFJ/NVALJ)
            ENDIF
C     3-----
          ELSE
C     3-----
C      -----  Non-nuclei are given a polarizability of 1.
C
            ALFJ = ONE
            ZJ = ZERO
C     3-----
          ENDIF
C
C    -----  pointers to arrays w.r.t. expansion center -J-
C
          JF = (J-1)*4
          NZF = JF*3
C
C    -----  position vector -J- into -Q-
C
          q0(1) = XEXP(1,J)
          q0(2) = XEXP(2,J)
          q0(3) = XEXP(3,J)
C
C
C    -----  Distance vector between ii and j in -PQ-
C
          CALL DISTAB(q0,XPTS(1,I1),PQ,DIST)
            if (dist .lt. small) then
              write(iwr,95) anam(j), nxcent(i1), dist
  95          format(/,1x,'WARNING: interaction ',
     1   'between ', a16, ' and ', a16, ' at', e15.8,
     2   ' bohr distance: skipped')
              goto 290
            endif

          DMIND1 = ONE/DIST
          u = ONE
          FACTP = ONE
          FACTF = ONE
C
C    -----  Scale interaction between point charges according to Thole
C           (optional)
C
          IF (MODXZA .NE. 0) THEN
C     3-----
            S = (ALFEXT(I1)*ALFJ)**SIXTH
            u = DIST/S
C
            IF (ITHOLE .EQ. 1) THEN
C       4-----
              IF (u .LE. AFACT) THEN
                AV = u/AFACT
                FACTP = AV**4 - TWO*AV**3 + TWO*AV
                FACTF = FOUR*AV**3 - THREE*AV**4
              ENDIF
C       4-----
            ELSE
C       4-----
              AU = AFACT*u
              FACTP = (ONE - (PT5*AU + ONE)*EXP(-AU))
              FACTF = (ONE - (PT5*AU**2 + AU + ONE)*EXP(-AU))
C       4-----
            ENDIF
C     3-----
          ENDIF
C
C    -----  Dipole-dipole interaction tensor in B
C
          DMIN3 = DMIND1**3
          CALL DRFTPQ(PQ,DMIND1,DMIN3,ITHOLe,AFACT,u,B)
          if (odebug) CALL hATOUT(B,3,3,2,'B')
C
          IF (ZJ .NE. ZERO) THEN
C     3-----
C      -----  From nuclear charge at J
C
            IF ((field(:4) .ne. ' ') 
     1    .and. (ZI .NE. ZERO)) THEN
C       4-----
C        -----  Contributions at a charge
C
              DO K = 1, 3
                GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1)
     1               - PQ(K)*ZI*ZJ*DMIN3*FACTF
              ENDDO
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C       4-----
            ENDIF
C
            IF (POLI .AND. (FIELD(5:) .NE. ' ')) THEN
C       4-----
C        -----  Contributions at a polarizability
C        -----  Contribution due to field derivative of 
C               nuclei
C
              CALL MATVEC(B,DIPIND(IINDp),GRADT,3,.FALSE.)
C
C        -----  NOTE: --sign because we should have contracted 
C                     with -B
C
              CALL ADDUPVS(GRAD(IGRAD),GRADT,GRAD(IGRAD),-PT5*ZJ,3)
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C
C        -----  Contribution due to derivative of induced 
C               dipole due to nuclei
C
              DO K = 1, 3
                CALL ADDUPVS(DIFLD(IINDp,K),B(1,K),DIFLD(IINDp,K),ZJ,3)
              ENDDO
C       4-----
            ENDIF
C     3-----
          ENDIF
C
C      -----  Non bonding repulsion taken from CHARMM:
C             J.Comp.Chem. 4 (1983) 213
C
C      -----  This is called the pseudo- or model repulsion throughout
C             the program
C
            if ((field(:4) .ne. ' ') .and.
     1          (j .le. nat) .and.
     1          (iqmclr .eq. 1) .and. 
     1          (namej(:2) .ne. 'bq') .and.
     1          (nxcent(i1)(:2) .ne. 'qq') .and.
     2          (nxcent(i1)(:2) .ne. 'e ') .and.
     3          (nxcent(i1)(:2) .ne. '  ')) then
C       4-----
C        -----  This might be a close atom: apply distance
C               criterium for Pauli repulsion
C
            IF (DIST .LT. DSTMIN) THEN
C         5-----
C          -----  Store external point counter in array relating to
C                 atom, for calculation of exact integrals
C
C          -----  Calculate Pauli repulsion and
C                 derivative, using some model potential
C
C               IF (IREPOPT .EQ. 0) THEN
C
C                 The necessary ingredients:
C
C            -----  Check if the point represents a group
C
              IF (NAMEI(:5) .EQ. 'group') THEN
C           6-----
C              -----  Non-bonded interactions evaluated only between
C                     internal atoms and individual members
C                     of a group:
C                     Skip the group-representing point
C
                GOTO 290
              ELSE
C
C              -----  1/R12 term for selected atoms
C
C              -----  Get polarizability of external atom
C
                CALL DRFNVAL(NAMEI,NVALI,ZNUC)
                IF (ALFI .NE. ZERO) THEN
                  AOVERNI = SQRT(ALFI/NVALI)
                ENDIF
C
C              -----  Calculate equilibrium LJ distance from
C                     "size" of internal and external atom
C
C              -----  Size of external atom: RI
C
                RI = RADEXT(I1)*RFACT
C
C              -----  Size of external atom: RJX
C
                RJX = RADAT(J)*RFACT
C
C              -----  In case of a H-bond, the sizes need to be
C                     modified
C
C              -----  Check H-bond criterium
C
                    if ((ihbond .eq. 1)
     1                  .and. (dist .le. hbondl)) then
                      if(namej(:2).eq.'h'.and.
     1                  (namei(:2).eq.'n'.or.
     2                   namei(:2).eq.'o'.or.
     3                   namei(:2).eq.'f')) rjx=hbondr
                      if(namei(:2).eq.'h'.and.
     1                  (namej(:2).eq.'n'.or.
     2                   namej(:2).eq.'o'.or.
     3                   namej(:2).eq.'f')) ri=hbondr
                    endif
CMAS  changed Feb 7, 1996
C
C              -----  Calculate the 1/R12 LJ term for the close contact
C
                IF (ALFJ .NE. ZERO .AND. ALFI .NE. ZERO) THEN
                  PSEU = PSEUFAC*ALFJ*ALFI/(AOVERNJ+AOVERNI)
                  PSEU1 = (RI+RJX)**6
C
C                -----  and derivative
C
                  DO K = 1, 3
                    GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) -
     1                   TWELVE*PQ(K)*PSEU*PSEU1*(DMIND1**14)
                  ENDDO
                ENDIF
C          6-----
              ENDIF
C               ELSE IF (IREPOPT .EQ. 1) THEN
C
C            -----  Set some necessary blabla for integrals
C
C                  CALL DRFPSEU
C
C               ENDIF
C         5-----
            ENDIF
C       4-----
          ENDIF
 290      continue
C
C    -----  Electronic contributions
C           The field-gradient operator and field of 
C           expansion centre q (-J- = -Q-) at -ii-
C
C    -----  T.r(a) in GRADT2
C
          CALL MATVEC(B,q0,GRADT2,3,.FALSE.)
C
C    -----  From electronic charge distribution 
C           expanded around J
c
          IJ = 0
          DO J1 = 1, NUM
            DO JJJ = 1, J1
              IJ = IJ + 1
              valijs = zero
C       4-----
              ijexp = iexpc(ij)
c             IF ((ABS(D(IJ)) .GT. THRESH) .AND.
c    1              (IjEXP .EQ. J)) THEN
              if    (IjEXP .EQ. J) THEN
C         5-----
C          -----  density factor
C
                FAC = TWO
                IF (J1 .EQ. JJJ)  FAC = ONE
C
                DIP(1) = DX(IJ)
                DIP(2) = DY(IJ)
                DIP(3) = DZ(IJ)
                dip(4) = ol(ij)
C
                IF ((field(:4) .ne. ' ') 
     1        .and. (ZI .NE. ZERO)) THEN
C           6-----
C            -----  Contributions at a charge
C
C            -----  Overlap term: Sij*(-E(a;i) - T(a;i).r(a))
C
                  DO K = 1, 3
                    GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1)
     1               + (PQ(K)*DMIN3*FACTF + GRADT2(K))
     2                 *FAC*D(IJ)*OL(IJ)*ZI
                  ENDDO
C
C            -----  Dipole term: Mij.T(a;i)
C
                  CALL MATVEC(B,DIP,GRADT3,3,.FALSE.)
                  DO K = 1, 3
                    GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1)
     1               - GRADT3(K)*FAC*D(IJ)*ZI
                  ENDDO
                  if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C           6-----
                ENDIF
C
                IF (POLI .AND. (FIELD(5:) .NE. ' ')) THEN
C           6-----
C            -----  Contributions at a polarizability
C            -----  Contribution due to field derivative of 
C                   electrons
C
                  DO K = 1, 3
C             7-----
C              -----  -T(i;a) - O(i;a).r(a) in B2
C                     for overlap term
C
C              -----  O(a;i) in O
C
                    CALL DRFOPQ(PQ,DMIND1,O,K,ITHOLe,AFACT,u)
                    CALL MATVEC(O,q0,GRADT,3,.FALSE.)
C
C              -----  NOTE: scaled by -1. because O(i;a) = - O(a;i)
C
                    DO L = 1, 3
                      B2(L,K) = FAC*OL(IJ)*D(IJ)*(-B(L,K) + GRADT(L))
                    ENDDO
C
C              -----  add O(i;a).M from dipole term
C
                    CALL MATVEC(O,DIP,GRADT,3,.FALSE.)
C
C              -----  NOTE: --sign because O(i;a) = - O(a;i)
C
                    DO L = 1, 3
                      B2(L,K) = B2(L,K) - FAC*D(IJ)*GRADT(L)
                    ENDDO
C
C              -----  Contribution to derivative of inducing field
C              -----  NOTE: +-sign because electrons AND now source field!
C 
                    CALL ADDUPVS(DIFLD(IINDp,K),B2(1,K),
     1                           DIFLD(IINDp,K),ONE,3)
c
                    if (gamdrf .ne. 0.0) then
c
            rr(1,1) = rxx(ij)
            rr(1,2) = rxy(ij)
            rr(2,1) = rxy(ij)
            rr(1,3) = rxz(ij)
            rr(3,1) = rxz(ij)
            rr(1,4) = dx(ij)
            rr(4,1) = dx(ij)
            rr(2,2) = ryy(ij)
            rr(2,3) = ryz(ij)
            rr(3,2) = ryz(ij)
            rr(2,4) = dy(ij)
            rr(4,2) = dy(ij)
            rr(3,3) = rzz(ij)
            rr(3,4) = dz(ij)
            rr(4,3) = dz(ij)
            rr(4,4) = ol(ij)
c
            if (k .eq. 1) then
              call drfoab(ijexp,ijexp,nwtc,omega11)
c           contr = adotb(rr,omgab,16)*d(ij)*fac*pt5
            contr = ddot(16,rr,1,omgab,1)*d(ij)*fac*pt5
            grad(igrad+k-1) = grad(igrad+k-1) + contr*gamdrf
              call drfoab(ijexp,ijexp,nwtc,omega12)
c           contr = adotb(rr,omgab,16)*d(ij)*fac*pt5
            contr = ddot(16,rr,1,omgab,1)*d(ij)*fac*pt5
            grad(igrad+k-1) = grad(igrad+k-1) + contr*gamdrf
            else if (k .eq. 2) then
              call drfoab(ijexp,ijexp,nwtc,omega21)
c           contr = adotb(rr,omgab,16)*d(ij)*fac*pt5
            contr = ddot(16,rr,1,omgab,1)*d(ij)*fac*pt5
            grad(igrad+k-1) = grad(igrad+k-1) + contr*gamdrf
              call drfoab(ijexp,ijexp,nwtc,omega22)
c           contr = adotb(rr,omgab,16)*d(ij)*fac*pt5
            contr = ddot(16,rr,1,omgab,1)*d(ij)*fac*pt5
            grad(igrad+k-1) = grad(igrad+k-1) + contr*gamdrf
            else
              call drfoab(ijexp,ijexp,nwtc,omega31)
c           contr = adotb(rr,omgab,16)*d(ij)*fac*pt5
            contr = ddot(16,rr,1,omgab,1)*d(ij)*fac*pt5
            grad(igrad+k-1) = grad(igrad+k-1) + contr*gamdrf
              call drfoab(ijexp,ijexp,nwtc,omega32)
c           contr = adotb(rr,omgab,16)*d(ij)*fac*pt5
            contr = ddot(16,rr,1,omgab,1)*d(ij)*fac*pt5
            grad(igrad+k-1) = grad(igrad+k-1) + contr*gamdrf
            endif
            dself = d(ij)
            call onecdrf(k,iindp,ijexp,vr,rr,diifld,
     1                relay,index,dipindd,dipin2,dipix,contr)
            grad(igrad+k-1) = grad(igrad+k-1) 
     1       - contr*fac*gamdrf*pt5*dself
            valgrs = valgrs - contr*fac*gamdrf*pt5*dself
              valijs = valijs - contr*fac*gamdrf*pt5*dself
            valij = zero
c
            call onecsf(npol3,ndimb,nexp,ijexp,
     1     wt,dip,one,dipin1)
            CALL LUELMF(RELAY,dipin1,INDEX,NDIM,NDIM,DIPINDD)
            call clear(dipin2,ndimp)
            do jc = 1, npol
              jind = (jc-1)*3 + 1
              call getomat(diifld,o,npol,jc,k)
              call matvec(o,dipindd(jind),gradt,3,.false.)
              call addupvs(dipin2(iindp),gradt,dipin2(iindp),-one,3)
              call matvec(o,dipindd(iindp),gradt,3,.false.)
              call addupvs(dipin2(jind),gradt,dipin2(jind),-one,3)
            enddo
            CALL LUELMF(RELAY,dipin2,INDEX,NDIM,NDIM,DIPINDD)
c
          kl = 0
          do 1000, k1 = 1, num
c     3-----
            lmax = k1
            do 1100, l1 = 1, lmax
c       4-----
              kl = kl + 1
              klexp = iexpc(kl)
c             if (ijbit(kl) .eq. 0) goto 1100
c
c        -----  calculate addresses
c
              ik = ia(max(j1,k1)) + min(j1,k1)
              jk = ia(max(jjj,k1)) + min(jjj,k1)
              il = ia(max(j1,l1)) + min(j1,l1)
              jl = ia(max(jjj,l1)) + min(jjj,l1)
              ii = j1
              jj = jjj
              kk = k1
              ll = l1
              valijkl = zero
c
c        -----  calculate density factors
c
              dexch = (d(ik)*d(jl)+d(jk)*d(il))*gamdrf
c
c             if ((abs(dcoul) .gt. thresh2) .or.
c    1            (abs(dexch) .gt. thresh2)) then
c         5-----
                dip2(1) = dx(kl)
                dip2(2) = dy(kl)
                dip2(3) = dz(kl)
                dip2(4) = ol(kl)
                factkl = two
                if (l1 .eq. k1) factkl = one
                fact = fac*factkl
c
                if (k .eq. 1) then
                val = zero
                  call drfoab(klexp,ijexp,nwtc,omega11)
                  call matvec(omgab,dip,ph1,4,.false.)
c                 val = -pt5*fact*adotb(ph1,dip2,4)
                  val = -pt5*fact*ddot(4,ph1,1,dip2,1)
c
c          -----  factor 0.25 for double counting twice
c
                  grad(igrad+k-1) = grad(igrad+k-1) + dexch*val*pt25
                  call drfoab(klexp,ijexp,nwtc,omega12)
                  call matvec(omgab,dip,ph1,4,.false.)
c                 val = -pt5*fact*adotb(ph1,dip2,4)
                  val = -pt5*fact*ddot(4,ph1,1,dip2,1)
                  grad(igrad+k-1) = grad(igrad+k-1) + dexch*val*pt25
                else if (k .eq. 2) then
                  call drfoab(klexp,ijexp,nwtc,omega21)
                  call matvec(omgab,dip,ph1,4,.false.)
c                 val = -pt5*fact*adotb(ph1,dip2,4)
                  val = -pt5*fact*ddot(4,ph1,1,dip2,1)
                  grad(igrad+k-1) = grad(igrad+k-1) + dexch*val*pt25
                  call drfoab(klexp,ijexp,nwtc,omega22)
                  call matvec(omgab,dip,ph1,4,.false.)
c                 val = -pt5*fact*adotb(ph1,dip2,4)
                  val = -pt5*fact*ddot(4,ph1,1,dip2,1)
                  grad(igrad+k-1) = grad(igrad+k-1) + dexch*val*pt25
                else
                  call drfoab(klexp,ijexp,nwtc,omega31)
                  call matvec(omgab,dip,ph1,4,.false.)
c                 val = -pt5*fact*adotb(ph1,dip2,4)
                  val = -pt5*fact*ddot(4,ph1,1,dip2,1)
                  grad(igrad+k-1) = grad(igrad+k-1) + dexch*val*pt25
                  call drfoab(klexp,ijexp,nwtc,omega32)
                  call matvec(omgab,dip,ph1,4,.false.)
c                 val = -pt5*fact*adotb(ph1,dip2,4)
                  val = -pt5*fact*ddot(4,ph1,1,dip2,1)
                  grad(igrad+k-1) = grad(igrad+k-1) + dexch*val*pt25
                endif
            call onecrf(npol3,ndimb,nexp,ngran,klexp,vr,dip2,
     1                dexch,dipindd,contr)
                  grad(igrad+k-1) = grad(igrad+k-1) 
     1            + contr*pt25*pt5*fact
c         5-----
c             endif
c       4-----
 1100       continue
c     3-----
 1000     continue
        endif
c
c
C             7-----
          ENDDO
C
C            -----  Contract with induced dipole at -i-
C
                  CALL MATVEC(B2,DIPIND(IINDp),GRADT,3,.FALSE.)
C
C            -----  NOTE: --sign because electrons
C                   (cf. nuclei)
C
                  CALL ADDUPVS(GRAD(IGRAD),GRADT,GRAD(IGRAD),-PT5,3)
                  if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C           6-----
                ENDIF
C         5-----
              ENDIF
C
            ENDDO
C       4-----
          ENDDO
C
 50       CONTINUE
C   2-----
        ENDDO
C
C    -----  Force on a charge due to reaction field
C
        IF ((ZI .NE. ZERO) .AND. (FIELD(5:) .NE. ' ')) THEN
C   2-----
C    -----  Calculate dipole-derivatives induced 
C           by II and calculate the force at ii
C           due to these
C
          DO K = 1, 3
C     3-----
            CALL LUELMF(RELAY,DFLD(1,K),INDEX,NDIM,NDIM,DIPINDD)
C
C      -----  From interaction with classical system
C
            DO IGR = 1, NGRAN
              GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) +
     1      PT5*ddot(NDIM,VR(1,NEXP4+IGR),1,DIPINDD,1)
c    1      PT5*ADOTB(VR(1,NEXP4+IGR),DIPINDD,NDIM)
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
            ENDDO
C
C      -----  From interaction with nuclei
C
            GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) +
     1      PT5*ddot(NDIM,VR(1,NEXP4+NGRAN+1),1,DIPINDD,1)
c    1      PT5*ADOTB(VR(1,NEXP4+NGRAN+1),DIPINDD,NDIM)
            if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C
C      -----  From interaction with electrons
C
            CALL ELRF(NPOL3,NDIMB,NEXP,NUM,
     1                VR,D,DX,DY,DZ,OL,IEXPC,DIPINDD,GRADEL)
            GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) +
     1      PT5*GRADEL
            if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRAD')
C     3-----
          ENDDO
C   2-----
        ENDIF
C
C  -----  Force on polarizability due to reaction field
C
        IF (POLI .AND. (FIELD(5:) .NE. ' ')) THEN
C   2-----
C    -----  Calculate dipole-derivatives induced 
C           by JJ and induced dipoles
C           and calculate the force at ii due to these
C
          DO K = 1, 3
            CALL LUELMF(RELAY,DIFLD(1,K),INDEX,NDIM,NDIM,DIPINDD)
C
C      -----  From interaction with classical system
C
            DO IGR = 1, NGRAN
              GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) +
     1      PT5*ddot(NDIM,VR(1,NEXP4+IGR),1,DIPINDD,1)
c    1      PT5*ADOTB(VR(1,NEXP4+IGR),DIPINDD,NDIM)
              if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRADc')
            ENDDO
C
C      -----  From interaction with nuclei
C
            GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) +
     1      PT5*ddot(NDIM,VR(1,NEXP4+NGRAN+1),1,DIPINDD,1)
c    1      PT5*ADOTB(VR(1,NEXP4+NGRAN+1),DIPINDD,NDIM)
            if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRADn')
C
C      -----  From interaction with electrons
C
            CALL ELRF(NPOL3,NDIMB,NEXP,NUM,
     1                VR,D,DX,DY,DZ,OL,IEXPC,DIPINDD,GRADEL)
            GRAD(IGRAD+K-1) = GRAD(IGRAD+K-1) +
     1      PT5*GRADEL
c            write(iwr,*) 'gradel= ', pt5*gamdrf*pt25*gradel
            if (odebug) CALL hATOUT(GRAD,3,NXTP,2,'EXTGRADe')
C     3-----
          ENDDO
C   2-----
        ENDIF
C
        IF (POLI) IMP = IMP + 1
C 1----- do next external point
      ENDDO
      RETURN
      END
      SUBROUTINE ADDUPVS(A,B,C,SCALE,N)
C------
C      returns array C = A + scale*B of length N
C------
      IMPLICIT REAL (A-H, O-Z)
C
      DIMENSION A(N), B(N), C(N)
C
      DO I = 1, N
C 1-----
        C(I) = A(I) + SCALE*B(I)
C 1-----
      ENDDO
C
      RETURN
      END
      SUBROUTINE ADDUPMS(A,B,C,SCALE,N,M)
C------
C      returns array C = A + scale*B of dimension NxM
C------
      IMPLICIT REAL (A-H, O-Z)
C
      DIMENSION A(N,M), B(N,M), C(N,M)
C
      DO I = 1, N
C 1-----
        DO J = 1, M
C   2-----
          C(I,J) = A(I,J) + SCALE*B(I,J)
C   2-----
        ENDDO
C 1-----
      ENDDO
C
      RETURN
      END
      SUBROUTINE DRFOPQ(PQ,DMIND1,O,K,ITHOLE,AFACT,SCALD)
C
C     Kth component of third derivative of 1/|PQ|
C
C     P.Th. van Duijnen, IBM-Kingston, 1985
C
C
      IMPLICIT REAL (A-H,O-Z)
      DIMENSION       PQ(3),O(3,3)
      DATA ZERO, ONE, THREE, FIFTN /0.0, 1.0, 3.0, 15.0/
      DATA PT5, TWOPT5  /0.5, 2.5/
C
      R2 = DMIND1**2
      R5 = DMIND1*R2**2
      R7 = R5*R2
C
      IF (ITHOLE .EQ. 1) THEN
C 1-----
        IF (SCALD .LT. AFACT) THEN
C
C  * * *  Conical charge distribution
C
          V = SCALD/AFACT
C
          FACT=V**4
          FACT7 = THREE * fact * R7
          FACT5 = THREE * fact * R5
	ELSE
          FACT=ONE
          FACT7 = FIFTN * R7
          FACT5 = THREE * R5
        ENDIF
C 1-----
      ELSE IF (ITHOLE .EQ. 2) THEN
C 1-----
C       Exponentially decaying spherical charge distribution
C
        AU = AFACT*SCALD
        TERM = (ONE - (PT5*AU**2 + AU + ONE)*EXP(-AU))
        FACT5 = (THREE*TERM - PT5*AU**3*EXP(-AU)) * R5
        FACT7 = (FIFTN*TERM - (PT5*AU**4 + TWOPT5*AU**3)*EXP(-AU)) * R7
C 1-----
      ELSE
        FACT=ONE
        FACT7 = FIFTN * R7
        FACT5 = THREE * R5
      ENDIF
C

      DO 20 I = 1,3
        DO 10 J = 1,3
          TERM5=ZERO
          IF (I.EQ.J) TERM5 = TERM5 + PQ(K)
          IF (I.EQ.K) TERM5 = TERM5 + PQ(J)
          IF (J.EQ.K) TERM5 = TERM5 + PQ(I)
          O(I,J) = TERM5*FACT5-FACT7*PQ(I)*PQ(J)*PQ(K)
 10     CONTINUE
 20   CONTINUE
      RETURN
      END



      SUBROUTINE DWTVRcla(KXYZ,nclas,XEXP,WT,VR,
     1           XSURF,XNORM,AREA,IEPS,INEQ)
C------
C       Calculation of derivative of
C       (expanded) source and reaction fields
C       of/on (formal) QM particles (nuclei, electrons)
C       or representations (DP charges, Mulliken charges
C       and dipoles) thereof, at polarizabilities,
C       boundary elements and external charges.
C
C       --------  P.Th. van Duijnen, IBM-KINGSTON 1985, and
C                 Groningen, Dec. 1991.
C
C       --------  Adapted from WTVRCAL
C                 KXYZ gives the index of the 
C                 cartesian derivative
C                 1=X; 2=Y; 3=Z
C                 A.H. de Vries, Daresbury Lab 1997, 
C                 and Groningen, 1997
C------
      IMPLICIT REAL (A-H,O-Z)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
C
C-----  Dummy arrays
C
      DIMENSION XSURF(3,NBEM),XNORM(3,NBEM),AREA(NBEM)
      DIMENSION XEXP(3,NEXP),WT(NWTR,NWTC),
     1          VR(NWTR,NWTC)
C
C-----  Common blocks
C
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/mollab)
C
INCLUDE(comdrf/drfpar)
INCLUDE(comdrf/extinf)
INCLUDE(comdrf/grinf)
INCLUDE(comdrf/drfamb)
INCLUDE(comdrf/neqpar)
INCLUDE(comdrf/drfbem)
INCLUDE(comdrf/rad)
C
C-----  Local variables
C
      LOGICAL KAPNOZ
C
      CHARACTER*16 NAMJ
C
      DIMENSION P(3), q(3)
      DIMENSION PQ(3),W(3),B(3,3),BQ(3),DELKIQ(3),DELLIQ(3)
      DIMENSION QI(3), T(3,3), TQ(3), TNI(3)
      REAL    FQINI, EXPKD, FKAPONE, DIST, DMIND1, DMIN3
      REAL    XKIQ, XLIQ
      DIMENSION O(3,3)
C
      CHARACTER*8 ERRMSG(3)
C
      DATA ERRMSG/'PROGRAM','STOP IN','-DWTVRCA'/
      DATA THIRD/.33333333333333333333333333333D00/
      DATA SIXTH/.16666666666666666666666666667D00/
      DATA TWO,THREE,FOUR,TWELVE/2.0D00,3.0D00,4.0D00,12.0D00/
      DATA ZERO,PT5,PT75 /0.0D00,0.5D00,0.75D00/
      DATA ONE,ONEPT5 /1.0D00,1.5D00/
C
C-----  BEGIN
C
      IF (IBEM .NE. 0) THEN
C 1-----
        IF (INEQ .EQ. 0) THEN
C   2-----
          IF (IEPS .EQ. 0) THEN
C     3-----
            EPS = EPS1
            KAPPA = KAPPA1
          ELSE
            EPS = EPS2
            KAPPA = KAPPA2
C     3-----
          ENDIF
C   2-----
        ELSE
C   2-----
          IF (IEPS .EQ. 0) THEN
C     3-----
            EPS = EPSNEQ1
            KAPPA = KAPNEQ1
          ELSE
            EPS = EPSNEQ2
            KAPPA = KAPNEQ2
C     3-----
          ENDIF
C   2-----
        ENDIF
C
C  -----  Set logical  KAPNOZ
C         for non-zero ionic strength
C
        KAPNOZ = KAPPA .NE. ZERO
C
C  -----  Initialize some important factors
C
        EXPKD = ONE
        FKAPONE = ONE
        PI=FOUR*ATAN(ONE)
        EPSFACT= ONE/(TWO*PI*(ONE+EPS))
        KAPPAS = KAPPA**2
C 1-----
      ENDIF
C
      IF (MODXZA .EQ. 0) ITHOLE = 0
      ITHOL = ITHOLE
C
C-----  zfp and vrp must be cleared,
C       since their values do not
C       depend on the co-ordinates of 
C       the expansion centres
C
      CALL CLEAR(WT(1,1),(NEXP4+NGRAN+1)*NDIM)
      CALL CLEAR(VR(1,1),(NEXP4+NGRAN+1)*NDIM)
C
c     CALL CLEAR(WT(1,NEXP4+NGRAN+1),NDIM)
c     CALL CLEAR(VR(1,NEXP4+NGRAN+1),NDIM)
C
C-----  Loop over the expansion centra
C
      DO J = 1, NEXP
C 1-----
        IF (J .LE. NAT) THEN
C   2-----
C    -----  Nucleus at expansion centre
C
C    -----  Skip ambiguous atoms
C
          IF (NAMBPT(J) .NE. 0) GOTO 500
C
C    -----  Nuclear charge -ZA-
C
          ZA = CZAN(J)
          NAMJ = ANAM(J)
C
C    -----  Polarisability of atom corresponding to expansion centre
C
c         ALFJ = ALFA(NAMJ,0,IER)
          alfj = alfat(j)
C   2-----
        ELSE
C   2-----
C    ----- Non-nulcei are given a polarizability 1.
C
          ALFJ = ONE
C   2-----
        ENDIF
C
C  -----  Pointer to arrays w.r.t. expansion centre -J-
C
        JF = (J-1)*4
C
C  -----  Position vector -J- into -Q-
C
        q(1) = XEXP(1,J)
        q(2) = XEXP(2,J)
        q(3) = XEXP(3,J)
C
C  -----  Loop over polarizable points
C
c       DO 300, II = 1, NPOL
          ii = nclas
C   2-----
          NP = MPOL(II)
C
C    -----  Skip ambiguous points. If polarisability is required for
C           these points w.r.t. the QM system, add basis functions
C           to represent the polarisability
C
          IF (NCUTPT(NP) .NE. 0) GOTO 300
C
C    -----  Position vector into -P-
C
          P(1) = XPTS(1,NP)
          P(2) = XPTS(2,NP)
          P(3) = XPTS(3,NP)
C
C    -----  Pointer in field arrays w.r.t. polarizable point
C
          IF = (II-1)*3
C
C    -----  Calculate distance vector between -Q- and -P-
C    -----  PQ contains (p-q)
C
          CALL DISTAB(q,P,PQ,DIST)
C
C    -----  Skip very close polarisabilities (as may occur for
C           ambiguous atoms)
C
          IF (DIST .LE. 1.0D-03) GOTO 300
C
          DMIND1 = ONE/DIST
          DMIN3 = DMIND1*(DMIND1**2)
          FACTP = ONE
          FACTF = ONE
          V = ONE
c
          alfi = alfext(np)
          if (alfi .eq. zero) alfi = one
C
C    -----  Account for penetration effects (optional)
C
          IF (MODXZA .NE. 0) THEN
C     3-----
            S = (ALFJ*ALFi)**SIXTH
            V = DIST/S
            IF (ITHOLE .EQ. 1) THEN
C       4-----
              IF (V .LE. AFACT) THEN
                AV = V/AFACT
                FACTP = AV**4 - TWO*AV**3 + TWO*AV
                FACTF = FOUR*AV**3 - THREE*AV**4
              ENDIF
C       4-----
            ELSE IF (ITHOLE .EQ. 2) THEN
C       4-----
              AU = AFACT*V
              FACTP = (ONE - (PT5*AU + ONE)*EXP(-AU))
c              FACTP = (ONE - (PT5*AU - ONE)*EXP(-AU))
              FACTF = (ONE - (PT5*AU**2 + AU + ONE)*EXP(-AU))
C       4-----
            ENDIF
C     3-----
          ENDIF
          FACTP = FACTP*DMIND1
          FACTF = FACTF*DMIN3
C
C    -----  B(3,3) = t(p;q) : field gradient of charge in -P- at -Q-
C           Note that the interaction may be scaled
C
          CALL DRFTPQ(PQ,DMIND1,DMIN3,ITHOL,AFACT,V,B)
C
C    -----  O(3,3) = o(KXYZ;p;q) : KXYZ derivative of
C           field gradient of charge in -P- at -Q-
C           o = -d/drj t(i;j) = d/dri t(i;j)
C           Note that the interaction may be scaled
C
          CALL DRFOPQ(PQ,DMIND1,O,KXYZ,ITHOL,AFACT,V)
C
C    -----  Calculate -W- = o(KXYZ;p;q) . q , this is part of the
C           Taylor expansion of the field
C
          CALL MATVEC(O,q,W,3,.FALSE.)
C
C    -----  -WT- and -VR- matrices for expanded field and potential
C           of charge (distribution) in expansion centra
C           at the polarizable points (-WT-) and vice versa (-VR-)
C
C           Depending on the type of sources (charges, dipoles,
C           charge distributions), specified in DRFINP by IFLDIN
C           and "recipients", specified by IFLDOUT, the matrices
C           are constructed partly or completely.
C
          DO 290, K = 1, 3
C     3-----
C      -----  derivative of the distance vector
C
            PQK = B(KXYZ,K)
            DO 280, L = 1, 3
C       4-----
C        -----  Copy -O- into -WT-  and/or -VR-
C
C               This expansion can be used to calculate the field and
C               reaction field of a unit dipole in -Q- (or -J-, the
C               expansion centre) at polarizable point -P-.
C               Therefore, it is always calculated except when only
C               distributed monopoles are used to expand the source
C               AND reaction fields of the quantum motif
C
C        -----  Note: DRFOPQ gives d/dQ t(Q;P) !!
C
              IF (IFLDIN .GT. 1) THEN
                WT(IF+K,JF+L) =  O(K,L)
              ENDIF
              IF (IFLDOUT .GT. 1) THEN
                VR(IF+K,JF+L) = -O(K,L)
              ENDIF
C       4-----
  280       CONTINUE
C
C      -----  If the source/reaction field is not expanded (i.e. only
C             distributed mono- /dipoles are used), only the potential
C             part is stored in -WT-/-VR-
C
            IF (IFLDIN .GT. 2) THEN
              WT(IF+K,JF+4) = -W(K) + pqk
            ELSE
              WT(IF+K,JF+4) = PQK
            ENDIF
C
            IF (IFLDOUT .GT. 2) THEN
              VR(IF+K,JF+4) = +W(K) - pqk
            ELSE
              VR(IF+K,JF+4) = -PQK
            ENDIF
C
C      -----  Form -ZFN-: the fields in the polarizable points
C             due to the INTERNAL nuclei
C             -ZFN- is in fact the sum of the nuclear fields
C             and potentials
C
            IF (J .LE. NAT) THEN
              WT(IF+K,NEXP4+NGRAN+1) = WT(IF+K,NEXP4+NGRAN+1) + PQK*ZA
              VR(IF+K,NEXP4+NGRAN+1) = VR(IF+K,NEXP4+NGRAN+1) - PQK*ZA
            ENDIF
C     3-----
  290     CONTINUE
C
C    -----  End of polarizable points
C   2-----
  300   CONTINUE
C
C  -----  Fields (and fields dot normal) at boundary elements
C         due to charges, dipoles and charge distributions
C         (expanded) in the expansion centra
C
C  -----  Loop over boundary elements
C         
C         NOTE: DERIVATIVES NOT DONE YET!!!!
C
        DO 400, NI = 1, NBEM
C   2-----
C    -----  QI: Vector from expansion centre -J- to
C           boundary element -NI- = (i-q)
C           DIST: Length of QI
C
          CALL DISTAB(q,XSURF(1,NI),QI,DIST)
          DMIND1 = ONE/DIST
          DMIN2 = DMIND1**2
          DMIN3 = DMIND1*DMIN2
          IF (KAPNOZ) THEN
            EXPKD = EXP(-(KAPPA*DIST))
            FKAPONE = ONE + (KAPPA*DIST)
          ENDIF
C
C    -----  FQINI:  Field of unit (positive) charge
C                   in -J- at -NI-, contracted with
C                   normal vector in -NI- = (i-q).n(i)/dist**3
C                   = f(q;i) . n(i)
C
C           It is also the negative of the potential of a dipole
C           in the direction of n(i) at the expansion centre
C
          FQINI = DMIN3*ddot(3,QI,1,XNORM(1,NI),1)
c         FQINI = DMIN3*ADOTB(QI,XNORM(1,NI),3)
C
C    -----  REACTION potential energy operator
C           at expansion centre, first term in the expansion
C           containing contribution of unit dipoles w(i)
C
C                XKIQ = K(i;q) S(i)
C
C        = (eps*(1+kappa*dist)*exp(-kappa*dist) - 1) f(i;q).n(i) S(i)
C
C    -----  The minus sign is a result of the use of the
C           inverted field: needed is f(i;q), FQINI=f(q;i).n(i)
C
          XKIQ = - (EPS*FKAPONE*EXPKD - ONE)*FQINI*AREA(NI)
C
          IF (KAPNOZ) THEN
C
C      -----  REACTION potential energy operator
C             at expansion centre, first term in the expansion,
C             containing contribution of unit charges z(i)
C
C                XLIQ = L(i;q) S(i)
C
C         = (1 - exp(-kappa*dist) ) V(i;q) S(i)
C
            XLIQ = (ONE - EXPKD)*DMIND1*AREA(NI)
          ENDIF
C
C    -----  Check if expansion centre coincides with
C           position of nucleus; exclude ambiguous atoms
C
          IF ((J .LE. NAT) .AND. (NAMBPT(J) .EQ. 0)) THEN
C     3-----
C      -----  POTENTIAL of all source nuclear charges in -J- at -NI-
C             scaled with 1/(2pi(1+eps)), as input for coupling
C             equations for w(i)
C
C                  V(q;i) = sum(q) Q(q) / dist
C
C      -----  This is the boundary element part of -ZFN-
C
            IF (IFLDIN .GT. 2) THEN
              WT(NPOL3+NI,NEXP4+NGRAN+1) =
     1            WT(NPOL3+NI,NEXP4+NGRAN+1) + EPSFACT*ZA*DMIND1
            ENDIF
C
C      -----  The reaction potential energy operator at the
C             expansion centre -J-, multiplied by the source
C             nuclear charge
C
C      -----  The interaction energy is evaluated through contracting
C             this array with the induced dipole density array
C
            IF (IFLDOUT .GT. 2) THEN
              VR(NPOL3+NI,NEXP4+NGRAN+1) =
     1                    VR(NPOL3+NI,NEXP4+NGRAN+1) + XKIQ*ZA
            ENDIF
C
            IF (KAPNOZ) THEN
C       4-----
C        -----  MINUS FIELD of all source nuclear charges in -J- at -NI-
C               contracted with normal vector at -NI-,
C               scaled with eps/(2pi(1+eps)), as input for
C               coupling equations for z(i)
C
C                    f(q;i) = Q(q) (i-q)/ dist**3
C
              IF (IFLDIN .GT. 2) THEN
                WT(NPOL3+NI+NBEM,NEXP4+NGRAN+1) =
     1          WT(NPOL3+NI+NBEM,NEXP4+NGRAN+1) - EPS*EPSFACT*ZA*FQINI
              ENDIF
C
C        -----  The reaction potential energy operator at the
C               expansion centre -J-, multiplied by the source
C               nuclear charge
C
C        -----  The interaction energy is evaluated through contracting
C               this array with the induced charge density array
C
              IF (IFLDOUT .GT. 2) THEN
                VR(NPOL3+NI+NBEM,NEXP4+NGRAN+1) =
     1          VR(NPOL3+NI+NBEM,NEXP4+NGRAN+1) + XLIQ*ZA
              ENDIF
C       4-----
            ENDIF
C     3-----
          ENDIF
C
C    -----  Expansion of source potential and field
C           of surface charge distribution
C           and reaction potentials at and around the expansion centra
C
C             GENERAL:
C
C         Expansion in Taylor series in x around q:
C
C   For source potential: V(x;i) = V(q;i) + del(x) V(x;i) (x=q) .(x-q)
C         = V(q;i) - f(q;i).q + f(q;i).x
C
C   For source field:     f(x;i) = f(q;i) + del(x) f(x;i) (x=q) .(x-q)
C         = f(q;i) + t(q;i).q - t(q;i).x
C
C   For reaction potential due to induced dipoles (operator)
C                         K(i;x) = K(i;q) + del(x) K(i;x) (x=q) .(x-q)
C   = K(i;q) - [(eps*(1+kd)*exp(-kd) -1)*t(i;q).n(i) -
C                eps*(kappa**2)*exp(-kd)*f(i;q).n(i)*(q-i)].q
C            + [(eps*(1+kd)*exp(-kd) -1)*t(i;q).n(i) -
C                eps*(kappa**2)*exp(-kd)*f(i;q).n(i)*(q-i)].x
C
C   For reaction potential due to induced charges (operator)
C                         L(i;x) = L(i;q) + del(x) L(i;x) (x=q) .(x-q)
C   = L(i;q) - [(1+kd)*exp(-kd) -1)*f(i;q)].q
C            + [(1+kd)*exp(-kd) -1)*f(i;q)].x
C
C-----
C      SOURCE POTENTIAL IN -NI- (scaled with 1/(2pi(1+eps))
C
          IF (IFLDIN .GT. 2) THEN
C-----
C      V(q;i) - f(q;i).q
C-----
            WT(NPOL3+NI,JF+4) = EPSFACT*(DMIND1-DMIN3*
     +      ddot(3,QI,1,q,1))
c    +      ADOTB(QI,q,3))
          ELSE
            WT(NPOL3+NI,JF+4) = EPSFACT*DMIND1
          ENDIF
C-----
C      the operator f(q;i) (.x)
C-----
          IF (IFLDIN .GT. 1) THEN
            DO 320, K = 1, 3
              WT(NPOL3+NI,JF+K) = EPSFACT*DMIN3*QI(K)
  320       CONTINUE
          ENDIF
C
C    -----  Calculate del(i) f(q;i) = t(q;i) = t(i;q) = T
C
          CALL DRFTPQ(QI,DMIND1,DMIN3,0,ONE,ONE,T)
C
C    -----  Calculate TNI = t(q;i) . n(i)
C
          CALL MATVEC(T,XNORM(1,NI),TNI,3,.FALSE.)
C
          IF (KAPNOZ) THEN
C     3-----
C      MINUS SOURCE FIELD IN -NI- contracted with normal vector in -NI-
C                           and scaled with (eps/(2pi(1+eps))
C-----
C
C      -----  Calculate contraction of t(q;i) with origin of
C             expansion q: TQ = t(q;i).q
C
            CALL MATVEC(T,q,TQ,3,.FALSE.)
C-----
C      - [f(q;i).n(i) + [t(q;i).q].n(i)]
C-----
            IF (IFLDIN .GT. 2) THEN
              WT(NPOL3+NI+NBEM,JF+4) = - EPS*EPSFACT*
     +       (FQINI + ddot(3,TQ,1,XNORM(1,NI),1))
c    +       (FQINI + ADOTB(TQ,XNORM(1,NI),3))
            ELSE
              WT(NPOL3+NI+NBEM,JF+4) = - EPS*EPSFACT*FQINI
            ENDIF
C-----
C      The operator - [-t(q;i) (.x)] .n(i)
C                 =   [ t(q;i).n(i)] (.x)
C-----
            IF (IFLDIN .GT. 1) THEN
              DO 330, K = 1, 3
                WT(NPOL3+NI+NBEM,JF+K) = EPS*EPSFACT*TNI(K)
  330         CONTINUE
            ENDIF
C     3-----
          ENDIF
C-----
C      REACTION POTENTIAL DUE TO DIPOLE IN -NI- AT -X-
C-----
C
C    -----  Calculate del(x) K(i;x) (x=q) *S(i) = DELKIQ
C
C      The minus sign for the second term remains, since both
C      field dot normal(FQINI) and vector (QI) are from -J- to -NI-
C      whereas the reverse of vectors is needed
C
          IF (IFLDOUT .GT. 1) THEN
            DO 340, K = 1, 3
              DELKIQ(K)=  ((EPS*FKAPONE*EXPKD - ONE)*TNI(K) -
     1                  EPS*KAPPAS*EXPKD*FQINI*QI(K))*AREA(NI)
C-----
C      The operator del(x) K(i;x) (x=q) *S(i) (.x)
C-----
              VR(NPOL3+NI,JF+K)= DELKIQ(K)
  340       CONTINUE
          ENDIF
C
          IF (IFLDOUT .GT. 2) THEN
C-----
C      [K(i;q) - del(x) K(i;x) (x=q) .q] S(i)
C-----
            VR(NPOL3+NI,JF+4)=  XKIQ - 
     +      ddot(3,DELKIQ,1,q,1)
c    +      ADOTB(DELKIQ,q,3)
          ELSE
C-----
C       K(i;q)
C-----
            VR(NPOL3+NI,JF+4)=  XKIQ
          ENDIF
C
          IF (KAPNOZ) THEN
C     3-----
C      REACTION POTENTIAL DUE TO CHARGE IN -NI- AT -X-
C-----
C      Calculate del(x) L(i;x) (x=q) *S(i) = DELLIQ
C
C      Minus sign is a result of using f(q;i) = (i-q)/dist**3,
C      whereas f(i;q) is needed
C
            IF (IFLDOUT .GT. 1) THEN
              DO 350, K = 1, 3
                DELLIQ(K)=-(ONE-FKAPONE*EXPKD)*QI(K)*DMIN3*AREA(NI)
C-----
C      The operator [del(x) L(i;x) (x=q)] *S(i) (.x)
C-----
                VR(NPOL3+NI+NBEM,JF+K) = DELLIQ(K)
  350         CONTINUE
            ENDIF
C
            IF (IFLDOUT .GT. 2) THEN
C-----
C      [L(i;q) - del(x) L(i;x) (x=q) . q] *S(i)
C-----
              VR(NPOL3+NI+NBEM,JF+4)=  XLIQ - 
     +        ddot(3,DELLIQ,1,q,1)
c    +        ADOTB(DELLIQ,q,3)
            ELSE
C-----
C       L(i;q)
C-----
              VR(NPOL3+NI+NBEM,JF+4) = XLIQ
            ENDIF
C     3-----
          ENDIF
C   2-----
  400   CONTINUE
 500    CONTINUE
C 1-----
      END DO
C
      RETURN
      eND
      subroutine putomat(omat,o,n,jindx,kxyz)
      REAL omat, o
      integer jindx, kxyz
      dimension omat(n,3,3,3)
      dimension o(3,3)
c
      do i = 1, 3
        do j = 1, 3
          omat(jindx,kxyz,i,j) = o(i,j)
        enddo
      enddo
c
      return
      end
      subroutine getomat(omat,o,n,jindx,kxyz)
      REAL omat, o
      integer jindx, kxyz
      dimension omat(n,3,3,3)
      dimension o(3,3)
c
      do i = 1, 3
        do j = 1, 3
          o(i,j) = omat(jindx,kxyz,i,j)
        enddo
      enddo
c
      return
      end
      subroutine onecrf(npol3,ndimb,nexp,ngran,iexpc,vr,fp,
     1                fact,dipind,eelmol)
c------
c      this routine calculates the interaction energy between
c      the induced dipoles and charges and the electronic
c      density
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy arrays
c
      dimension vr(npol3+ndimb,nexp*4+2)
      dimension dipind(npol3+ndimb)
      dimension fp(4)
      dimension f(4)
c
      data zero, one, two /0.0d00, 1.0d00, 2.0d00/
c
c-----  initialize interaction energy
c
      eelmol = zero
c    -----  assign expansion centre to charge distribution
c
          iexp = iexpc
c
c    -----  set pointer
c
          ip = (iexp-1)*4
c
c    -----  premultiply density with dipole and overlap moments
c           of the charge distribution
c
          f(1) = fact*fp(1)
          f(2) = fact*fp(2)
          f(3) = fact*fp(3)
          f(4) = fact*fp(4)
c
c    -----  execute expansion
c
          do 300, k = 1, 4
            do 400, l = 1, npol3+ndimb
              eelmol = eelmol - f(k)*vr(l,ip+k)*dipind(l)
  400       continue
  300     continue
c
          extcont = zero
            DO IGR = 1, NGRAN
           contr = ddot(Npol3+ndimb,VR(1,NEXP*4+IGR),1,DIPIND,1)
c          contr = ADOTB(VR(1,NEXP*4+IGR),DIPIND,Npol3+ndimb)
c            write(6,*) "exch-ext = ", contr
              extcont = extcont - contr
            ENDDO
c            write(6,*) "exch-ext total= ", extcont
      return
      end
      subroutine onecsf(npol3,ndimb,nexp,iexpc,wt,fp,
     1                fact,sf)
c------
c      this routine calculates the interaction energy between
c      the induced dipoles and charges and the electronic
c      density
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy arrays
c
      dimension wt(npol3+ndimb,nexp*4+2)
      dimension sf(npol3+ndimb)
      dimension fp(4)
      dimension f(4)
c
      data zero, one, two /0.0d00, 1.0d00, 2.0d00/
c
c-----  initialize interaction energy
c
      call clear(sf,npol3+ndimb)
c    -----  assign expansion centre to charge distribution
c
          iexp = iexpc
c
c    -----  set pointer
c
          ip = (iexp-1)*4
c
c    -----  premultiply density with dipole and overlap moments
c           of the charge distribution
c
          f(1) = fact*fp(1)
          f(2) = fact*fp(2)
          f(3) = fact*fp(3)
          f(4) = fact*fp(4)
c
c    -----  execute expansion
c
          do 300, k = 1, 4
            do 400, l = 1, npol3+ndimb
              sf(l) = sf(l) - f(k)*wt(l,ip+k)
  400       continue
  300     continue
c
  200   continue
  100 continue
      return
      end
      subroutine onecdrf(kxyz,iindp,iexpc,vr,fp,diifld,
     1                relay,index,dipindd,dipin2,dipix,erfen)
c------
c      this routine calculates the interaction energy between
c      the induced dipoles and charges and the electronic
c      density
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
INCLUDE(../m4/common/iofile)
INCLUDE(comdrf/drfpar)
c
c-----  dummy arrays
c
      dimension vr(ndim,nwtc)
      dimension dipix(nwtc,ndim)
      dimension fp(4,4)
      dimension relay(nwtr,nwtr)
      dimension index(ndim)
      dimension dipindd(ndim), dipin2(ndim)
      dimension diifld(npol,3,3,3)
      dimension o(3,3)
      dimension gradt(3)
c
      data zero, one, two /0.0d00, 1.0d00, 2.0d00/
c
c-----  initialize interaction energy
c
      erfen = zero
c    -----  assign expansion centre to charge distribution
c
          iexp = iexpc
c
c    -----  set pointer
c
          ip = (iexp-1)*4
c
c    -----  execute expansion
c
      do k = 1, 4
        do l = 1, 4
          amomij = fp(k,l)
          do m = 1, ndim
            dipindd(m) = dipix(ip+l,m)
          enddo
          call clear(dipin2,ndim)
          do jc = 1, npol
            jind = (jc-1)*3 + 1
            call getomat(diifld,o,npol,jc,kxyz)
            call matvec(o,dipindd(jind),gradt,3,.false.)
            call addupvs(dipin2(iindp),gradt,dipin2(iindp),-one,3)
            call matvec(o,dipindd(iindp),gradt,3,.false.)
            call addupvs(dipin2(jind),gradt,dipin2(jind),-one,3)
          enddo
          CALL LUELMF(RELAY,dipin2,INDEX,NDIM,NDIM,DIPINDD)
          ehelp = zero
          do m = 1, ndim
            ehelp = ehelp + vr(m,ip+k)*dipindd(m)*amomij
          enddo
c         write (iwr,*) k,l,amomij,ehelp
          erfen = erfen + ehelp
        enddo
      enddo
c
      return
      end

