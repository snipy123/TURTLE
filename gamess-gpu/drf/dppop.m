      subroutine dppop(xscm)
c------
c      sets memory partitioning for standard mulliken and
c      dipole preserving charge analysis with equal partitioning
c      of overlap distribution contributions between originating
c      centres
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
INCLUDE(../m4/common/infoa)
c
INCLUDE(../m4/common/limy)
INCLUDE(comdrf/iofil)
c
INCLUDE(comdrf/drfdaf)
c
      character *8 errmsg(3)
      dimension xscm(*)
      data errmsg /'program', 'stop in', '-dppop-'/
c
c     call setscm(i10)
c     call cmem(loadcm)
c     loc10 = loccm(xscm(i10))
      lwor = igmem_max_memory()
      i10 = igmem_alloc(lwor)
      i20=i10+nx
      i30=i20+nx+1
      i40=i30+nat*4
      last = i40 + 2*(nat*(nat+1))
      need = last - i10
      if (need .gt. lwor) then
        write(iwr,1001)
 1001   format(/,'Insufficient memory allocated for DPC analysis')
        call hnderr(3,errmsg)
      endif
      call dippop(xscm(i10),xscm(i20),xscm(i30),xscm(i40))
      call gmem_free(i10)
c
      return
      end
      subroutine dippop(a,b,q,d)
c------
c      perform dipole preserving analysis, based on equal partitioning
c      of overlap distributions contributions between originating
c      centres
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/iofile)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy arrays
c
      dimension a(nx), b(nx)
      dimension q(nat,4), d(nat*(nat+1)/2,4)
c
c-----  common blocks
c
cxxxINCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/nshel)
INCLUDE(comdrf/mollab)
INCLUDE(comdrf/nmorb)
cxxxINCLUDE(comdrf/opt)
INCLUDE(comdrf/auxdrf)
cxxxINCLUDE(comdrf/scfopt)
      character *8 title2,scftyp
      common/restrz/title2(10),scftyp
c
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/drfdaf)
c
INCLUDE(comdrf/runpar)
c
INCLUDE(../m4/common/dump3)
      common /restar/ nprint,ipadrestar(702)
c
c-----  local variables
c
      dimension sum(4)
      dimension imat(4)
      logical out, mcout
c
c-----  data statements
c
c     data imat /53,54,55,12/
      data imat/4,5,6,1/
      dimension potnuc(10),ostf(6)
      logical ostf
      data one,two /1.0d00,2.0d00/
c
c-----  begin
c
      out = nprint .eq. 3
c
      mcout = ((.not. mcupdt) .or. (imcout .eq. 5))
c
      if (mcout) then
        write(iwr,1001)
 1001   format(//t20,22('-')/t20,' dp analysis'/
     1 t20,22('-')/)
      endif
c
c-----  assign overlap distributions
c
      call lookupd
c
c-----  read density
c
      call rdedx(b,nx,ibl3pa,idaf)
cxxx  call daread(idafh,ioda,b,nx,16)
cxxx  if(scftyp.eq.'uhf') then
      if((scftyp.eq.'uhf') .or. (scftyp.eq.'rohf')
     1 .or. (scftyp .eq. 'gvb').or.(scftyp.eq.'grhf')) then
        call rdedx(a,nx,ibl3pb,idaf)
cxxx    call daread(idafh,ioda,a,nx,20)
        do 10 l=1,nx
          b(l)=b(l)+a(l)
   10 continue
      endif
c
c-----  loop over x,y,z dipole moments and overlap of distributions
c
      do 150 l=1,4
c
c  -----  read x, y, z, s
c
        do i=1,6
            ostf(i)=.false.
        enddo
        ostf(imat(l))=.true.
        call getmat(a,a,a,a,a,a,potnuc,num,ostf,ionsec)
c       call daread(idafh,ioda,a,nx,imat(l))
c
c  -----  set up loop over charge distributions
c
        ij=0
        do 140 i=1,num
          do 130 j=1,i
            if(i.eq.j) then
              t=one
            else
              t=two
            endif
            ij=ij+1
            a(ij)=a(ij)*b(ij)*t
  130     continue
  140   continue
c
c  -----  contract dipole and charges into mulliken dipoles
c         and charges
c
c       call condns(num,nat,a,d(1,l),q(1,l),icent,1.,sum(l))
        call condns(num,nat,a,d(1,l),q(1,l),icent,one,sum(l))
c
  150 continue
c
      if (out) call hatout(q,nat,4,5,'dip_q')
c
c-----  rearrange dipole moments for tdpop
c
      nn=0
      do 160 i=1,nat
        do 170 k=1,3
          nn=nn+1
          a(nn)=q(i,k)
  170   continue
  160 continue
c
c-----  calculate mulliken charges and dipoles and determine dp charges
c
      call tdpop(a,q(1,4),auxx)
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,260) sum(4)
  260   format(//t20,'total number of electrons'  ,f10.3/)
      endif
c
      return
      end
      subroutine lookupd
c------
c      looks up atomic centres of origin of overlap distributions
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  common blocks
c
INCLUDE(../m4/common/nshel)
INCLUDE(comdrf/nmorb)
c
INCLUDE(comdrf/drfdaf)
c
      do 50 ii=1,nshell
        i=katom(ii)
        mini=kmin(ii)
        maxi=kmax(ii)
        loci=kloc(ii)-mini
        do 30 m=mini,maxi
          li=loci+m
          itxyz(li)=m
          icent(li)=i
   30   continue
   50 continue
c
      return
      end
      subroutine condns(num,nat,d,c,q,icent,oc,sum)
c------
c  * * * condenses (inter) orbital distributions 'd' to (inter) atomic
c  * * * distributions 'c' and one centre distributions 'q'
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      dimension d(*),c(*),q(*),icent(*)
c
c  * * *  dimensions:
c  * * *  d  num*(num+1)/2
c  * * *  c  nat*(nat+1)/2
c  * * *  q  nat
c
      data zero,pt5/0.0d00,0.5d00/
c
      nn=nat*(nat+1)/2
      call clear(c,nn)
      call clear(q,nat)
c
      k=0
      sum=zero
      do 20 i=1,num
        ic=icent(i)
        im=ic*(ic-1)/2
        do 10 j=1,i
          k=k+1
          jc=icent(j)
          jm=im+jc
          del=oc*d(k)
          sum=sum+del
          c(jm)=c(jm)+del
          del=pt5*del
          q(ic)=q(ic)+del
          q(jc)=q(jc)+del
   10   continue
   20 continue
c
      return
      end
      subroutine tdpop(p,q,w)
c------
c  * * *  population analysis on occupied orbitals preserving the
c  * * *  dipole moment
c
c         input parameters
c         nat: number of internal nuclei
c         q(nat) gross mulliken electronic charges
c         p(3,nat) gross mulliken electronic dipoles
c         czan(nat) nuclear charges
c
c         output parameters
c         q(nat) first: mulliken gross atomic charges
c         q(nat) second: effective point charges conserving molecular
c         charge and dipole moment
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy arrays
c
      dimension p(3,nat)
      dimension q(nat), w(*)
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/nshel)
INCLUDE(comdrf/mollab)
INCLUDE(comdrf/nmorb)
INCLUDE(comdrf/opt)
INCLUDE(comdrf/auxdrf)
INCLUDE(comdrf/ihelp)
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/elpinf)
c
INCLUDE(comdrf/drfdaf)
c
INCLUDE(comdrf/runpar)
c
c-----  local variables
c
      character*16 names(1000)
c
c-----  data statements
c
      data zero,small/0.0d00,1.d-4/
c
c  * * *  mulliken analysis
c  * * *  reduce electronic charge with nuclear charge
c
      call clear(w,6)
      ctot=zero
      do  6 i=1,nat
cxxx    names(i)=anam(i)//bnam(i)
        names(i)=anam(i)
c
c  * * *  only intrinsic dipoles are redistributed
c
        do 4 l=1,3
          p(l,i)=q(i)*c(l,i)-p(l,i)
    4   continue
        q(i)=czan(i)-q(i)
        ctot=ctot+q(i)
        do 5 l=1,3
          w(l)=w(l)+q(i)*c(l,i)
          w(l+3)=w(l+3)+p(l,i)
    5   continue
    6 continue
c
c    -----  save mulliken charges and dipoles
c
c  * * *  output mulliken charges and dipoles
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,10)
   10   format(//t20,22('-')/t20,'gross mulliken charges'/
     1 t20,22('-')/)
      endif
c
      call printq(2,nat,q,c,names)
c
      if (abs(ctot).ge.small) then
        do 15, l = 1, 3
          w(l) = w(l)/ctot
   15   continue
        if ((.not. mcupdt) .or. (imcout .eq. 5)) then
          write(iwr,16)
   16     format(//t20,26('-')/t20,'center of mulliken charges'/
     1  t20,26('-')/)
          call hatout(w,1,3,2,' ')
          write(iwr,17)
   17     format(//t20,25('-')/t20,'charge free dipole moment'/
     1  t20,25('-')/)
          call hatout(w(4),1,3,2,' ')
        endif
      endif
c
c-----  write expansion centra on -da31-, record -101-
c
      nchrp(2) = nat
      ichrp(2) = 101
      nchrp(3) = nat
      ichrp(3) = 101
      nchrp(4) = nat
      ichrp(4) = 101
cxxx  call dawrit (idafdrf,iodadrf,c,3*nat,101,navdrf)
c
c * * * punch mulliken charges
c
cxxx  write(ipnch,*) title
cxxx  write(ipnch,*)'  name, charge, x, y, z'
cxxx  write(ipnch,*)' $mul-charges'
cxxx  do 20  i=1,nat
cxxx    write(ipnch,650) anam(i),bnam(i),q(i),(c(k,i),k=1,3)
cxx20 continue
cxxx  write(ipnch,*) ' $end'
c
c-----  write mulliken charges on -da31-, record -111-
c
c     call dawrit(idafdrf,iodadrf,q,nat,111,navdrf)
cxxx  call dawrit(idafdrf,iodadrf,q,nat,ilmc,navdrf)
c
c * * * punch mulliken dipoles
c
cxxx  write(ipnch,*)'  name, dipx,dipy,dipz, x, y, z'
cxxx  write(ipnch,*)' $mul-dipoles'
cxxx  do 30  i=1,nat
cxxx    write(ipnch,650) anam(i),bnam(i),(p(l,i),l=1,3),(c(k,i),k=1,3)
cxx30 continue
cxxx  write(ipnch,*) ' $end'
c
c-----  write mulliken dipoles on -da31-, record -112-
c
c     call dawrit(idafdrf,iodadrf,p,3*nat,112,navdrf)
cxxx  call dawrit(idafdrf,iodadrf,p,3*nat,ilmd,navdrf)
c
c-----  calculate dp charges
c
      call dpopan(nat,nat,c,c,q,p,w,ihlp)
c
c  * * *  printed output of td charges
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,500)
  500   format(
     1//t20,36('-'),/t20,'charges preserving the dipole moment',
     2/t20,36('-'))
      endif
c
      call printq(2,nat,q,c,names)
c
c-----  punch charges on internal points
c
cxxx  if(nprint.eq.-5) rewind ipnch
cxxx  write(ipnch,550)
cx550 format('----  dipole conserving charges  ------'/)
cxxx  write(ipnch,*)'  name, charge, x, y, z'
cxxx  write(ipnch,*)' $dp-charges'
cxxx  do 600 i=1,nat
cxxx    write(ipnch,650) anam(i),bnam(i),q(i),(c(k,i),k=1,3)
cx600 continue
cxxx  write(ipnch,*) ' $end'
  650 format(a8,a2,6f10.6)
c
c-----  write dipole preserving charges on -da31-, record -114-
c
      nchrp(5) = nat
      ichrp(5) = 101
c     call dawrit(idafdrf,iodadrf,q,nat,114,navdrf)
cxxx  call dawrit(idafdrf,iodadrf,q,nat,ildc,navdrf)
c
      return
      end
      subroutine dpopan(ndip,npnts,cp,cq,q,p,w,isign)
c------
c      --------  p.th. van duijnen, ibm-kingston 1985 -----
c
c     ndip = number of dipole moments
c     npnts= number of expansion points
c     cp   = coordinates of dipoles
c     cq   = coordinates of expansion centers
c     q    = charges(input&output)
c     p    = dipoles
c     w    = work space
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      dimension cp(3,ndip),q(ndip),p(3,ndip),w(*)
      dimension cq(3,npnts)
      dimension isign(npnts)
c
      dimension ri(3),ar(3),br(3),cr(3),dr(3),b(3,3),xav(3)
      dimension bvec(3,3),ia(3),ib(3)
c
      data ia/0,1,3/
      data ib/0,3,6/
      data zero,one/0.d00,1.d00/
      data thresh,smallw/1.0d-05,1.0d-10/
c
      weight(x)= exp(-x**2)
c
c-----  begin
c
c-----  loop over the muliken charges and dipoles
c
      do 400 i=1,ndip
c
c  -----  position vector in ar
c
        ar(1)=cp(1,i)
        ar(2)=cp(2,i)
        ar(3)=cp(3,i)
c
c  -----  bl is used for scaling the weight function
c
        bl=10000000.0d0
        do 15 l=1,npnts
          call distab(ar,cq(1,l),br,bll)
          if(bll.lt.bl.and.bll.gt.thresh) bl=bll
   15   continue
c
c  -----  loop over expansion points for finding averages etc.
c
        nsign=0
        sum=zero
        call clear(xav,3)
        call clear(b,9)
c
        do 35 l=1,npnts
c
c    -----  position vector in ri
c
          do 20 k=1,3
            ri(k)=cq(k,l)
   20     continue
c
c    -----  distance to dipole(i) into cr
c
          call distab(ri,ar,cr,al)
c
c    -----  weighting function
c
          wl=weight(al/bl)
c
c         if (wl .gt. small) then
c
            nsign=nsign+1
            isign(nsign)=l
            w(nsign)=wl
            sum=sum+wl
            call accum (ri,xav,wl,3)
c
c    -----  update matrix b
c
            do 30 im=1,3
              do 30 jm=1,3
                b(im,jm)=b(im,jm)+ri(im)*ri(jm)*wl
   30       continue
c
c         endif
c
   35   continue
c
c  -----  average coordinates in xav
c
        fact=one/sum
        do 36 im=1,3
          xav(im)=xav(im)*fact
   36   continue
c
c  -----  complete matrix b
c
        do 38 im=1,3
          do 38 jm=1,3
            b(im,jm)=b(im,jm)*fact-xav(im)*xav(jm)
   38   continue
c
c  -----  diagonalize matrix b
c
        call clear(cr,3)
        call shrink(b,b,3)
cxxx    call diagiv(b,bvec,cr,ia,3,3,3)
        call jacobi(b,ia,3,bvec,ib,3,cr,2,2,
     * 1.0d-08)
cxxx    call jacobi(a,iky,newb,q,ilifq,nrow,e,iop1,iop2,
cxxx * thresh)
c
c  -----  charge-free dipole in dr
c
        do 140 l=1,3
          dr(l)=-p(l,i)
  140   continue
c
c  -----  transform dipole vector
c
        call matvec(bvec,dr,ar,3,.true.)
c
c  -----  form u(dag)(p-q<x>)
c
        do 150 im=1,3
          dr(im)=ar(im)/(cr(im)+thresh*(cr(3)+thresh))
  150   continue
c
c  -----  transform result to br
c
        call matvec(bvec,dr,br,3,.false.)
c
c  -----  loop  over significant points and compute partial charges
c
        do 160 l=1,nsign
          ll=isign(l)
c
c    -----  position of point l relative to centre
c
          do 155 k=1,3
            ri(k)=cq(k,ll)-xav(k)
  155     continue
c
c    -----  charge on atom l
c
          qad=w(ll)*fact*ddot(3,br,1,ri,1)
c         qad=w(ll)*fact*adotb(br,ri,3)
          q(ll)=q(ll)-qad
  160   continue
  400 continue
c
      return
      end
      subroutine dppope(xscm)
c------
c      drives the mulliken and dp charge analysis with
c      charges distributions assigned on the basis of
c      distance criteria (in stead of dividing contributions
c      between source centra as in dppop)
c
c      namelist $expanc
c
c      icnexp: electronic expansion centra option
c
c           0: employ only atomic centra as expansion centra (default)
c           1: add centre of charge as expansion centre to the
c              atomic centra
c           2: add centre of charge and centra to be read from
c              $expc as expansion centra to atomic centra
c           3: add centra to be read from $expc as expansion centra
c              to atomic centra
c           4: use centre of charge as sole expansion centre
c           5: use centre of charge and centra to be read from
c              $expc as expansion centra
c           6: use only centra read from $expc as expansion centra
c           7: use each centre of overlap distribution as expansion cent
c              (this option implies the use of atomic centra, since
c               one-centre s-s overlap distributions are located
c               at the atom centre)
c
c          -n: define extra expansion centra if overlap distributions
c              are about equally distant from defined expansion centra
c
c              note: newly defined expansion centra are added to the lis
c              and available straight away
c
c      iexpas: option for assignment of overlap distributions
c
c          -3: all overlap distributions are assigned to the
c              geometric middle of the originating centres
c          -2: assign according to least-squares fit, but in case
c              of ambiguity to centre of charge
c          -1: assign all two-centre overlap distributions to the centre
c              of charge
c           0: if no unambiguous assignment can be made, assign
c              distribution to centre of charge
c           1: if no unambiguous assignment can be made, let it go
c              astray (default)
c           2: assign according to least squares fit to potential
c              due to overlap charge and dipole
c              only with icnexp < 4 !!!
c              because one-centre distributions are assigned to that cen
c
c      ifitc : option for centra at which the potential of overlap
c              distributions is to be calculated for fitting procedure
c              (with iexpas=2 only)
c
c           0: use the same centra as defined by icnexp(above) (default)
c              only with icnexp >= 0!!!!
c           1: use atomic centra only
c           2: use atomic centra + centre of charge
c           3: use atomic centra + centre of charge + centra read
c              from input ($fitc)
c           4: use atomic centra + centra read from input ($fitc)
c           5: use centra read from input ($fitc) only
c
c
c      iexpcn: dp expansion centra option
c
c           0: employ only atomic centra as expansion centra (default)
c           1: add centre of charge as expansion centre to the
c              atomic centra
c           2: add centre of charge and centra to be read from
c              $expx as expansion centra to atomic centra
c           3: add centra to be read from $expx as expansion centra
c              to atomic centra
c           4: use centre of charge as sole expansion centre
c           5: use centre of charge and centra to be read from
c              $expx as expansion centra
c           6: use only centra read from $expx as expansion centra
c           7: use each centre of overlap distribution as expansion cent
c              (this option implies the use of atomic centra, since
c               one-centre s-s overlap distributions are located
c               at the atom centre)
c           !! allowed only with icnexp = 7 !!
c
c      iunit: unit of length for extra expansion centres found on input
c           0: bohr (default)
c           1: angstrom
c
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
c
INCLUDE(comdrf/ihelp)
INCLUDE(comdrf/opt)
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/drfdaf)
c
INCLUDE(comdrf/elpinf)
INCLUDE(comdrf/expan)
c
INCLUDE(comdrf/runpar)
cahv new call to asgnrf
INCLUDE(../m4/common/nshel)
INCLUDE(../m4/common/symtry)
      common/junk3/ptr(3,144),dtr(6,288),ftr(10,480)
      common /restar/ nprint
c
      dimension xscm(*)
c
c-----  local variables
c
      dimension xex(3,maxex)
      character*80 text
      character *8 errmsg(3)
      logical out, mcout
      logical oradial
      character*10 duma
      dimension cm(3)
c
      logical defnew, each, asscen
c
      namelist /expanc2/icnexp,iexpas,ifitc,iexpcn,iunit
c
c      data icnexp, iexpas, ifitc, iexpcn, iunit  /0,1,0,0,0/
      data  ifitc, iunit  /0,0/
      data errmsg /'program', 'stop in', '-dppope-'/
c      data expat /.false./
      data oradial /.true./
      data bohr /.529177249d00/
      data zero, one /0.0d00,1.0d00/
c
c...  comdrf/expan
c
      icnexp = 0
      iexpas = 1
      iexpcn = 0
      expat  = .false.
c
c-----  begin
c
      noprt = 1
c
      out =noprt.eq.1.and.nprint.eq.3
c
c
      mcout = ((.not. mcupdt) .or. (imcout .eq. 5))
c
      if (mcout) then
        write(iwr,1000)
 1000   format(//t20,22('-')/t20,'alternative dp analysis'/
     1 t20,22('-')/)
      endif
c
      rewind ir
      read(ir,expanc2,end=1)
c
c-----  check validity of options
c
    1 continue
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,expanc2)
      endif
c
      if ((icnexp .le. 0 .or. icnexp .eq. 3 .or.
     1     icnexp .eq. 6) .and. (iexpas .eq. 0 .or.
     2     iexpas .eq. -1 .or. iexpas .eq. -2)) then
        write(iwr,1001) icnexp, iexpas
 1001   format(/,' input parameters icnexp= ',i2,
     1         ' and iexpas= ',i2,' conflict',/,
     2         ' please change them on input: $expanc ')
        call hnderr(3,errmsg)
      endif
      if (iexpcn .eq. 7 .and. icnexp .ne. 7) then
        write(iwr,1011) iexpcn, icnexp
 1011   format(/,' input parameters iexpcn= ',i2,
     1         ' and icnexp= ',i2,' conflict',/,
     2         ' please change them on input: $expanc ')
        call hnderr(3,errmsg)
      endif
      if (iexpas .eq. 2) then
        if (ifitc .eq. 0 .and. icnexp .lt. 0) then
          write(iwr,1021) icnexp, ifitc
 1021     format(/,' input parameters icnexp= ',i2,
     1         ' and ifitc= ',i2,' conflict',/,
     2         ' please change them on input: $expanc ')
          call hnderr(3,errmsg)
        endif
        if (icnexp .gt. 3) then
          write(iwr,1022) icnexp, iexpas
 1022     format(/,' input parameters icnexp= ',i2,
     1         ' and iexpas= ',i2,' conflict',/,
     2         ' please change them on input: $expanc ')
          call hnderr(3,errmsg)
        endif
      endif
c
      ufact = one
      if (iunit .eq. 1) ufact = one/bohr
c
c
c-----  define electronic expansion centra
c
      icnexa = abs(icnexp)
      defnew = icnexp .lt. 0
      each = icnexa .eq. 7 .or. iexpas .eq. -3
      asscen = iexpas .le. 0
c
c-----  initialize
c
      nexpc=0
      nex = 0
c
c-----  check if atomic centra are required as expansion centra
c
      if (icnexa .le. 3 .or. each) then
        nexpc = nat
        expat = .true.
      endif
c
c-----  check if centre of charge is required as expansion centre
c
      if (icnexa .eq. 1 .or. icnexa .eq. 2 .or.
     1      icnexa .eq. 4 .or. icnexa .eq. 5) then
        nex = nex + 1
        expnam(nex) = ' cent '
        call drfcm(xex(1,nex))
        icch = nexpc + 1
      endif
c
c-----  read expansion centra from input if required
c       (data block beginning with $expc)
c       and store them temporarily in xex
c       currently, a maximum of 50 expansion centra to be read in is all
c
      if (icnexa .eq. 2 .or. icnexa .eq. 3 .or.
     1      icnexa .eq. 5 .or. icnexa .eq. 6) then
        rewind(ir)
   10   read(ir,1100,end=99) text
 1100   format(a80)
        if (text(:6) .ne. ' $expc') goto 10
   20   read(ir,1100) text
        if (text(:5) .eq. ' $end') goto 30
        nex = nex + 1
c
        if (nex .gt. maxex) then
          write(iwr,1200) maxex
 1200     format(/' number of extra expansion centra on $expc ',
     1             'greater than ',i4,/,
     2             ' increase maxex near common blocks /expanc/')
          call hnderr(3,errmsg)
        endif
c
        read(text,1300) expnam(nex),(xex(k,nex),k=1,3)
 1300   format(a10,3f20.10)
        do 25, k = 1, 3
          xex(k,nex) = xex(k,nex)*ufact
   25   continue
        goto 20
   99   write(iwr,*)' list $expc not found on input file, ',
     1               'please check'
        call hnderr(3,errmsg)
   30   continue
      endif
c
      nexpc = nexpc + nex
c
c-----  check assignment method and define points in which potential is
c       to be calculated
c
      nfitc = 0
      nexf = 0
      if (iexpas .eq. 2) then
        if (ifitc .eq. 0) then
          nfitc = nexpc
        endif
        if (ifitc .ge. 1 .and. ifitc .le. 4) then
          nfitc = nat
        endif
        if (ifitc .eq. 2 .or. ifitc .eq. 3) then
          nexf = nexf + 1
        endif
        if (ifitc .ge. 3 .and. ifitc .le. 5) then
c
c    -----  dummy read points where potential is to be read
c
          rewind(ir)
   11     read(ir,1100,end=199) text
          if (text(:6) .ne. ' $fitc') goto 11
   21     read(ir,1100) text
          if (text(:5) .eq. ' $end') goto 31
          nexf = nexf + 1
c
          if (nexf .gt. maxex) then
            write(iwr,1201) maxex
 1201       format(/' number of extra expansion centra on $fitc ',
     1             'greater than ',i4,/,
     2             ' increase maxex near common blocks /expanc/')
            call hnderr(3,errmsg)
          endif
c
          read(text,1300) duma,dum,dum,dum
          goto 21
  199     write(iwr,*)' list $fitc not found on input file, ',
     1               'please check'
          call hnderr(3,errmsg)
   31     continue
        endif
        nfitc = nfitc + nexf
      endif
c
c-----  set memory partitioning
c
c        xscm
c        ovlap at ixo
c        dipx  at ixdx
c        dipy  at ixdy
c        dipz  at ixdz
c        fexp  at ixfx
c        cexp  at ixc
c        iexpc ar ixie
c
c        note: integer array before some real arrays # expansion centra
c              may be enlarged in asgnrf!!!
c
c     call setscm(i10)
c     call cmem(loadcm)
c     loc10 = loccm(xscm(i10))
      lwor = igmem_max_memory()
      i10 = igmem_alloc(lwor)
      ixo = i10
      ixdx = ixo + nx
      ixdy = ixdx + nx
      ixdz = ixdy + nx
      ixfx = ixdz + nx
      ixel = ixfx + 3*nfitc + 1
cahv
      ixis = ixel + nfitc*225 + 1
cahv
      ixie = ixis + nw196(5)
      ixdel = ixie + 2*nx + 1
      ixc = ixdel + nexpc*225
      last = ixie + 3*nexpc + 1
c
c     need = loc10 + last - i10
c     need = loc10 + last - i10
c     call setc(need)
      call clear(xscm(ixo),last-ixo+1)
c
c-----  fill in expansion centra in xscm
c
      ixex = ixc-1
      if (icnexa .le. 3 .or. each) then
c
c  -----  atomic centra
c
        do 100, i = 1, nat
          do 200, k= 1, 3
            ixex = ixex + 1
            xscm(ixex) = c(k,i)
  200     continue
  100   continue
      endif
c
c-----  extra expansion centra
c
      do 300, i = 1, nex
        do 400, k = 1, 3
          ixex = ixex + 1
          xscm(ixex) = xex(k,i)
  400   continue
  300 continue
c
c-----  define centra at which potential is to be calculated
c
      if (iexpas .eq. 2) then
        if (ifitc .eq. 0) then
c
c    -----  copy expansion centra
c
          do 410, i = 1, 3*nexpc
            xscm(ixfx+i-1) = xscm(ixc+i-1)
  410     continue
        else
          ixf = ixfx - 1
          if (ifitc .ge. 1 .and. ifitc .le. 4) then
c
c      -----  copy nuclear coordinates
c
            do 420, i = 1, nat
              do 430, k = 1, 3
                ixf = ixf + 1
                xscm(ixf) = c(k,i)
  430         continue
  420       continue
          endif
c
          if (ifitc .eq. 2 .or. ifitc .eq. 3) then
c
c      -----  add centre of charge to centra at which potential
c             to be calculated
c
            call drfcm(xscm(ixf+1))
            ixf = ixf + 3
          endif
          if (ifitc .ge. 3 .and. ifitc .le. 5) then
c
c      -----  read extra centra at which the potential is to be evaluate
c
            rewind(ir)
   12       read(ir,1100) text
            if (text(:6) .ne. ' $fitc') goto 12
   22       read(ir,1100) text
            if (text(:5) .eq. ' $end') goto 32
c
            read(text,1300) duma,(xscm(ixf+k),k=1,3)
            do 23, k = 1, 3
              xscm(ixf+k) = xscm(ixf+k)*ufact
   23       continue
            ixf = ixf + 3
            goto 22
   32       continue
c
          endif
        endif
      endif
c
c-----  transform expansion centra with centre of charge
c
      call drfcm(cm)
      ic = ixc-1
      do 450, i = 1, nexpc
        do 460, k = 1, 3
          ic = ic + 1
          xscm(ic) = xscm(ic) - cm(k)
  460   continue
  450 continue
c
c-----  assign expansion centra according to requested criteria
c
cahv      call asgnrf(nfitc,nexpc,icch,iexpas,defnew,each,asscen,
cahv     1     xscm(ixo),xscm(ixdx),xscm(ixdy),xscm(ixdz),
cahv     1     xscm(ixfx),xscm(ixel),xscm(ixdel),
cahv     2     xscm(ixc),xscm(ixie))
c
c----- read in transformation matrices for s,p,d,f basis functions.
c
      call rdedx(ptr,nw196(1),ibl196(1),idaf)
      call rdedx(dtr,nw196(2),ibl196(2),idaf)
      call rdedx(ftr,nw196(3),ibl196(3),idaf)
c
c----- read in symmetry array - iso
c
      call rdedx(xscm(ixis),nw196(5),ibl196(5),idaf)
c
      call asgnrf(nfitc,nexpc,icch,iexpas,defnew,each,asscen,
     1 oradial,nshell,xscm(ixo),xscm(ixdx),xscm(ixdy),xscm(ixdz),
     1     xscm(ixfx),xscm(ixel),xscm(ixdel),
     2     xscm(ixc),xscm(ixie),xscm(ixis))
c
      if (out)  call imatou(xscm(ixie),num,num,3,'iexpc')
c
c-----  electronic expansion centra at ixce
c
      ixce = i10
      ixex = ixce
c
      if (.not. expat) then
c
c  -----  add the nuclei as expansion centra (for mulliken analysis)
c
        nexpc = nexpc + nat
        ixex = ixex - 1
        do 500, i = 1, nat
          do 510, k = 1, 3
            ixex = ixex + 1
            xscm(ixex) = c(k,i)
  510     continue
  500   continue
c
c  -----  reassign the overlap distributions
c
        do 520, i = 1, nx
          xscm(ixie+i-1) = xscm(ixie+i-1) + nat
  520   continue
c
      endif
c
c-----  rewrite expansion centra at xscm(ixc), overwriting overlap etc
c
      do 530, i = 1, 3*nexpc
        xscm(ixex+i-1) = xscm(ixc+i-1)
  530 continue
c
c-----  count overall expansion centra
c
c-----  initialize
c
      nexpx=0
      nex = 0
c
c-----  check if atomic centra are required as expansion centra
c
      if (iexpcn .le. 3) then
        nexpx = nat
      endif
c
c-----  check if centre of charge is required as expansion centre
c
      if (iexpcn .eq. 1 .or. iexpcn .eq. 2 .or.
     1      iexpcn .eq. 4 .or. iexpcn .eq. 5) then
        nex = nex + 1
      endif
c
c-----  count expansion centra from input if required
c       (data block beginning with $expx)
c       and store them temporarily in xex
c       currently, a maximum of 50 expansion centra to be read in is all
c
      if (iexpcn .eq. 2 .or. iexpcn .eq. 3 .or.
     1      iexpcn .eq. 5 .or. iexpcn .eq. 6) then
        rewind(ir)
  110   read(ir,1100,end=98) text
        if (text(:6) .ne. ' $expx') goto 110
  120   read(ir,1100) text
        if (text(:5) .eq. ' $end') goto 130
        nex = nex + 1
c
        if (nex .gt. maxex) then
          write(iwr,1210) maxex
 1210     format(/' number of extra expansion centra on $expx ',
     1             'greater than ',i4,/,
     2             ' increase maxex near common blocks /expanc/')
          call hnderr(3,errmsg)
        endif
c
        read(text,1300) duma,dum,dum,dum
        goto 120
   98   write(iwr,*)' list $expx not found on input file, ',
     1               'please check'
        call hnderr(3,errmsg)
  130   continue
      endif
c
      nexpx = nexpx + nex
c
c-----  overall expansion centra at ixcx
c
      ixcx = ixce + 3*nexpc
c
c-----  further memory partitioning
c
c       ovlap,dipx,dipy,dipz at ixo
c       density              at ixd(respectively)
c       charges and dipoles  at ixq
c       workspace            at ixw
c       dp charges           at ixdp
c       workspace            at ixis
c
c
      ixo = ixcx + 3*nexpx
      ixd = ixo + nx
      ixq = ixd + nx
      ixw = ixq + 4*nexpc
      ixdp = ixw + max(nexpx,6)
      ixie = ixdp + nexpx
      ixis = ixie + nx
      last = ixis + nexpx + 1
c     need = loc10 + last - i10
c     call setc(need)
c
      nnew = 3*nx + 4*nexpc + max(nexpx,6) + 5*nexpx
      call clear(xscm(ixcx),nnew)
c
      call daread(idafh,ioda,xscm(ixie),nx,46)
c
c-----  call mulliken and dp charge calc. driver
c
      call dippope(nexpc,nexpx,xscm(ixce),xscm(ixcx),xscm(ixie),
     1             xscm(ixo),xscm(ixd),xscm(ixq),xscm(ixw),
     2             xscm(ixdp),xscm(ixis))
c     call setc(loadcm)
      call gmem_free(i10)
c
      return
      end
_IF()
      subroutine assign2(nfit,nexp,icch,iexpas,defnew,each,asscen,
     1           oradial,ovl,
     1           dipx,dipy,dipz,xexf,elpot,delpot,xexp,iexpc)
c------
c         assign expansion centres: internal atoms should come first
c         coordinates are taken relative to centre of nuclear charge
c
c      --------   p.th. van duijnen, groningen    1992 -----
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy variables
c
      dimension xexp(3,*)
      dimension iexpc(nx)
      dimension ovl(nx), dipx(nx), dipy(nx), dipz(nx)
      dimension xexf(3,nfit), delpot(nexp,225)
      dimension elpot(nfit,225)
      logical defnew, each, asscen
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/bas)
INCLUDE(../m4/common/nshel)
INCLUDE(comdrf/opt)
INCLUDE(comdrf/tim)
INCLUDE(comdrf/ijpair)
INCLUDE(comdrf/sym)
INCLUDE(comdrf/ssgg)
INCLUDE(comdrf/stv)
INCLUDE(comdrf/rys)
c
INCLUDE(comdrf/drfamb)
c
INCLUDE(comdrf/dafil)
c
      common /c_of_m/pcm,qcm,rcm
c
c-----  local variables
c
      dimension cm(3)
      dimension anorms(1024),
     1           css(2048),cps(2048),cds(2048),cfs(2048),cgs(2048)
c
      logical onec
      logical norm,double
      logical block,blocks,blocki
      logical some,out
      logical repeat, onetwo
c
      character*8 block1, block2
c
      dimension dij(225)
      dimension ijx(35),ijy(35),ijz(35)
      dimension xs(5,7)  ,ys(5,7)  ,zs(5,7)
      dimension xt(5,5)  ,yt(5,5)  ,zt(5,5)
      dimension xv(5,5,5),yv(5,5,5),zv(5,5,5)
c     character *8 errmsg(3)
c
c-----  data statements
c
c     data errmsg /'program ','stop in ','-assign-'/
      data block1 /'blocks  '/
      data block2 /'blocki  '/
      data maxrys /5/
      data rln10  /2.30258d+00/
      data zero   /0.0d+00/
      data pt5    /0.5d+00/
      data one    /1.0d+00/
      data two    /2.0d+00/
      data pi212  /1.1283791670955d+00/
      data pi32 /5.56832799683170d+00/
      data sqrt3  /1.73205080756888d+00/
      data sqrt5  /2.23606797749979d+00/
      data sqrt7  /2.64575131106459d+00/
      data pt75 /0.75d+00/
      data pt187 /1.875d+00/
      data pt6562 /6.5625d+00/
      data ten23 /1.d+23/
      data tols, told1, told2, told3 /1.d-02, 1.d-04, 1.d-20, 1.d-03/
      data ijx    / 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1              1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     2              1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     3              1, 1, 1, 1, 1/
      data ijy    / 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1              1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     2              1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     3              1, 1, 1, 1, 1/
      data ijz    / 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1              1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     2              1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     3              1, 1, 1, 1, 1/
c
cxxx
      noprt = 1
cxxx
      tol=rln10*itol
      out =noprt.eq.1.and.nprint.eq.3
      some=noprt.eq.0.and.nprint.ne.-5
      norm=normf.ne.1.or.normp.ne.1
      blocks=blktyp.eq.block1.and.noprt.eq.0
      blocki=blktyp.eq.block2.and.noprt.eq.0
      block =blocks.or.blocki
      num2=(num*(num+1))/2
c
c-----  define expansion centra
c
      call drfcm(cm)
      if (out) call hatout(cm  ,3,1   ,2,'cm  ')
c
c-----  read overlap integrals from da10
c
      call daread(idafh,ioda,ovl, num2,12)
c
c-----  calculate dipole moments relative to -cm-
c
cmw put the centre-of-mass information into the common
c   and call the gamess dipint
c   note that dipint was adapted for cm().
c   a common c_of_m is used to pass cm()
      pcm=cm(1)
      qcm=cm(2)
      rcm=cm(3)
cmw      call dipint(dipx,dipy,dipz,cm,num)
c     call dipint(dipx,dipy,dipz)
cahv  call dipxyz(dipx,dipy,dipz,num)
      call dipxyz(dipx,dipy,dipz)
c
      if (abs(iexpas) .ne. 2) then
c
c----- calculate radial overlap of charge distributions -----
c           ( this is accomplished by setting -lit-
c           and -ljt- equal to -1- regardless of
c           -ktype(ii)- and -ktype(jj)-. we are interested
c           in the -s- component only )
c
      if(out) write(iwr,9999)
 9999 format(//' radial overlap of charge distributions '
     1 /,1x,31(1h-))
c
      onetwo = iexpas .eq. -3
c
c----- unnormalize the basis functions -----
c           convert primitive normalization
c           to the -s- component, and then
c           renormalize the -s- function.
c
cahv      do 16 ii=1,nshell
cahv      i1=kstart(ii)
cahv      i2=i1+kng(ii)-1
cahv      mini=kmin(ii)
cahv      maxi=kmax(ii)
cahv      loci=kloc(ii)-mini
cahvc
cahv      snormi=one
cahv      pnormi=one
cahv      dnormi=one
cahv      fnormi=one
cahvcmw      gnormi=one
cahv      do 6 i=mini,maxi
cahv      li=loci+i
cahv      go to (1,2,6,6,3,6,6,6,6,6,
cahv     1       4,6,6,6,6,6,6,6,6,6,
cahv     2       5,6,6,6,6,6,6,6,6,6,
cahv     3       6,6,6,6,6),i
cahv    1 snormi=anorm(li)
cahv      go to 6
cahv    2 pnormi=anorm(li)
cahv      go to 6
cahv    3 dnormi=anorm(li)
cahv      go to 6
cahv    4 fnormi=anorm(li)
cahv      go to 6
cahvcmw    5 gnormi=anorm(li)
cahv    5 goto 6
cahv    6 continue
cahvc
cahv      do 7 ig=i1,i2
cahv      ai=ex(ig)
cahv      csi=cs(ig)
cahv      cpi=cp(ig)
cahv      cdi=cd(ig)
cahv      cfi=cf(ig)
cahvcmw      cgi=cg(ig)
cahv      csi=csi/snormi
cahv      cpi=cpi/pnormi
cahv      cdi=cdi/dnormi
cahv      cfi=cfi/fnormi
cahvcmw      cgi=cdi/gnormi
cahv      dum=ai+ai
cahv      facs=pi32/(dum* sqrt(dum))
cahv      facp=pt5*facs/dum
cahv      facd=pt75*facs/(dum*dum)
cahv      facf=pt187*facs/(dum*dum*dum)
cahvcmw      facg=pt6562*facs/(dum*dum*dum*dum)
cahv      cpi=cpi* sqrt(facp/facs)
cahv      cdi=cdi* sqrt(facd/facs)
cahv      cfi=cfi* sqrt(facf/facs)
cahvcmw      cgi=cgi* sqrt(facg/facs)
cahv      css(ig)=csi
cahv      cps(ig)=cpi
cahv      cds(ig)=cdi
cahv      cfs(ig)=cfi
cahvcmw      cgs(ig)=cgi
cahv    7 continue
cahvc
cahv      snorms=one
cahv      pnorms=one
cahv      dnorms=one
cahv      fnorms=one
cahvcmw      gnorms=one
cahv      snorm=zero
cahv      pnorm=zero
cahv      dnorm=zero
cahv      fnorm=zero
cahvcmw      gnorm=zero
cahv      do 9 ig=i1,i2
cahv      ei=ex(ig)
cahv      csi=css(ig)
cahv      cpi=cps(ig)
cahv      cdi=cds(ig)
cahv      cfi=cfs(ig)
cahvcmw      cgi=cgs(ig)
cahv      do 9 jg=i1,ig
cahv      ej=ex(jg)
cahv      csj=css(jg)
cahv      cpj=cps(jg)
cahv      cdj=cds(jg)
cahv      cfj=cfs(jg)
cahvcmw      cgj=cgs(jg)
cahvc
cahv      ee=ei+ej
cahv      dum=ee* sqrt(ee)
cahv      dums=csi*csj/dum
cahv      dump=cpi*cpj/dum
cahv      dumd=cdi*cdj/dum
cahv      dumf=cfi*cfj/dum
cahvcmw      dumg=cgi*cgj/dum
cahv      if(jg.eq.ig) go to 8
cahv      dums=dums+dums
cahv      dump=dump+dump
cahv      dumd=dumd+dumd
cahv      dumf=dumf+dumf
cahvcmw      dumg=dumg+dumg
cahv    8 snorm=snorm+dums
cahv      pnorm=pnorm+dump
cahv      dnorm=dnorm+dumd
cahv      fnorm=fnorm+dumf
cahvcmw      gnorm=gnorm+dumg
cahv    9 continue
cahv      if(snorm.gt.tols) snorms=one/ sqrt(snorm*pi32)
cahv      if(pnorm.gt.tols) pnorms=one/ sqrt(pnorm*pi32)
cahv      if(dnorm.gt.tols) dnorms=one/ sqrt(dnorm*pi32)
cahv      if(fnorm.gt.tols) fnorms=one/ sqrt(fnorm*pi32)
cahvcmw      if(gnorm.gt.tols) gnorms=one/ sqrt(gnorm*pi32)
cahvc
cahv      do 15 i=mini,maxi
cahv      li=loci+i
cahv      go to (10,11,11,11,12,12,12,12,12,12,
cahv     1       13,13,13,13,13,13,13,13,13,13,
cahv     2       14,14,14,14,14,14,14,14,14,14,
cahv     3       14,14,14,14,14),i
cahv   10 anorms(li)=snorms
cahv      go to 15
cahv   11 anorms(li)=pnorms
cahv      go to 15
cahv   12 anorms(li)=dnorms
cahv      go to 15
cahv   13 anorms(li)=fnorms
cahv      go to 15
cahv   14 go to 15
cahvcmw   14 anorms(li)=gnorms
cahv   15 continue
cahvc
cahv   16 continue
cahvc
cahvc     ----- ishell -----
cahvc
cahv      do 9000 ii=1,nshell
cahv      i=katom(ii)
cahv      iat=i
cahv      xi=c(1,i)
cahv      yi=c(2,i)
cahv      zi=c(3,i)
cahv      i1=kstart(ii)
cahv      i2=i1+kng(ii)-1
cahv      lit=1
cahv      mini=kmin(ii)
cahv      maxi=kmax(ii)
cahv      loci=kloc(ii)-mini
cahvc
cahv      snormi=one
cahv      pnormi=one
cahv      dnormi=one
cahv      fnormi=one
cahvcmw      gnormi=one
cahv      do 22 i=mini,maxi
cahv      li=loci+i
cahv      go to (17,18,22,22,19,22,22,22,22,22,
cahv     1       20,22,22,22,22,22,22,22,22,22,
cahv     2       21,22,22,22,22,22,22,22,22,22,
cahv     3       22,22,22,22,22),j
cahv   17 snormi=anorms(li)
cahv      go to 22
cahv   18 pnormi=anorms(li)
cahv      go to 22
cahv   19 dnormi=anorms(li)
cahv      go to 22
cahv   20 fnormi=anorms(li)
cahv      go to 22
cahv   21 go to 22
cahvcmw   21 gnormi=anorms(li)
cahv   22 continue
cahvc
cahvc     ----- jshell -----
cahvc
cahv      do 8000 jj=1,ii
cahv      j=katom(jj)
cahv      jat=j
cahv      onec=iat.eq.jat
cahv      if(onec) iexone=j
cahv      xj=c(1,j)
cahv      yj=c(2,j)
cahv      zj=c(3,j)
cahv      j1=kstart(jj)
cahv      j2=j1+kng(jj)-1
cahv      ljt=1
cahv      minj=kmin(jj)
cahv      maxj=kmax(jj)
cahv      locj=kloc(jj)-minj
cahv      snormj=one
cahv      pnormj=one
cahv      dnormj=one
cahv      fnormj=one
cahvcmw      gnormj=one
cahvc
cahv      do 28 j=minj,maxj
cahv      lj=locj+j
cahv      go to (23,24,28,28,25,28,28,28,28,28,
cahv     1       26,28,28,28,28,28,28,28,28,28,
cahv     2       27,28,28,28,28,28,28,28,28,28,
cahv     3       28,28,28,28,28),j
cahv   23 snormj=anorms(lj)
cahv      go to 28
cahv   24 pnormj=anorms(lj)
cahv      go to 28
cahv   25 dnormj=anorms(lj)
cahv      go to 28
cahv   26 fnormj=anorms(lj)
cahv      go to 28
cahv   27 go to 28
cahvcmw   27 gnormj=anorms(lj)
cahv   28 continue
cahvc
cahv      ljtmod=ljt+2
cahvc
cahv      iandj=ii.eq.jj
cahv      rr=(xi-xj)**2+(yi-yj)**2+(zi-zj)**2
cahv      nroots=(lit+ljt-2)/2+1
cahv      if(nroots.gt.maxrys) then
cahv         write(iwr,9997) maxrys,lit,ljt,nroots
cahv         call hnderr(3,errmsg)
cahv      endif
cahvc
cahv      ij=0
cahv      do 100 i=mini,maxi
cahv      jmax=maxj
cahv      if(iandj) jmax=i
cahv      do 100 j=minj,jmax
cahv      ij=ij+1
cahv       s(ij)=zero
cahv  100 continue
cahvc
cahvc     ----- i primitive -----
cahvc
cahv      do 7000 ig=i1,i2
cahv      ai=ex(ig)
cahv      arri=ai*rr
cahv      axi=ai*xi
cahv      ayi=ai*yi
cahv      azi=ai*zi
cahv      csi=css(ig)*snormi
cahv      cpi=cps(ig)*pnormi
cahv      cdi=cds(ig)*dnormi
cahv      cfi=cfs(ig)*fnormi
cahvcmw      cgi=cgs(ig)*gnormi
cahvc
cahvc     ----- j primitive -----
cahvc
cahv      jgmax=j2
cahv      if(iandj) jgmax=ig
cahv      do 6000 jg=j1,jgmax
cahv      aj=ex(jg)
cahv      aa=ai+aj
cahv      aa1=one/aa
cahv      dum=aj*arri*aa1
cahv      if(dum.gt.tol) go to 6000
cahv      fac= exp(-dum)
cahv      csj=css(jg)*snormj
cahv      cpj=cps(jg)*pnormj
cahv      cdj=cds(jg)*dnormj
cahv      cfj=cfs(jg)*fnormj
cahvcmw      cgj=cgs(jg)*gnormj
cahv      ax=(axi+aj*xj)*aa1
cahv      ay=(ayi+aj*yj)*aa1
cahv      az=(azi+aj*zj)*aa1
cahvc
cahvc     ----- density factor -----
cahvc
cahv      double=iandj.and.ig.ne.jg
cahv      ij=0
cahv      do 360 i=mini,maxi
cahv      go to (110,120,220,220,130,220,220,140,220,220,
cahv     1       150,220,220,160,220,220,220,220,220,170,
cahv     2       180,220,220,190,220,220,220,220,220,200,
cahv     3       220,220,210,220,220),i
cahv  110 dum1=csi*fac
cahv      go to 220
cahv  120 dum1=cpi*fac
cahv      go to 220
cahv  130 dum1=cdi*fac
cahv      go to 220
cahv  140 if(norm) dum1=dum1
cahv      go to 220
cahv  150 dum1=cfi*fac
cahv      go to 220
cahv  160 if(norm) dum1=dum1
cahv      go to 220
cahv  170 if(norm) dum1=dum1
cahv      go to 220
cahvcmw  180 dum1=cgi*fac
cahv  180 go to 200
cahv      go to 220
cahv  190 if(norm) dum1=dum1
cahv      go to 220
cahv  200 if(norm) dum1=dum1
cahv      go to 220
cahv  210 if(norm) dum1=dum1
cahv  220 continue
cahvc
cahv      jmax=maxj
cahv      if(iandj) jmax=i
cahv      do 360 j=minj,jmax
cahv      go to (230,250,350,350,260,350,350,270,350,350,
cahv     1       280,350,350,290,350,350,350,350,350,300,
cahv     2       310,350,350,320,350,350,350,350,350,330,
cahv     3       350,350,340,350,350),j
cahv  230 dum2=dum1*csj
cahv      if(.not.double) go to 350
cahv      if(i.gt.1) go to 240
cahv      dum2=dum2+dum2
cahv      go to 350
cahv  240 dum2=dum2+csi*cpj*fac
cahv      go to 350
cahv  250 dum2=dum1*cpj
cahv      if(double) dum2=dum2+dum2
cahv      go to 350
cahv  260 dum2=dum1*cdj
cahv      if(double) dum2=dum2+dum2
cahv      go to 350
cahv  270 if(norm) dum2=dum2
cahv      go to 350
cahv  280 dum2=dum1*cfj
cahv      if(double) dum2=dum2+dum2
cahv      go to 350
cahv  290 if(norm) dum2=dum2
cahv      go to 350
cahv  300 if(norm) dum2=dum2
cahv      go to 350
cahvcmw  310 dum2=dum1*cgj
cahv  310 if(double) dum2=dum2+dum2
cahv      go to 350
cahv  320 if(norm) dum2=dum2
cahv      go to 350
cahv  330 if(norm) dum2=dum2
cahv      go to 350
cahv  340 if(norm) dum2=dum2*sqrt3
cahv  350 continue
cahvc
cahv      ij=ij+1
cahv  360 dij(ij)=dum2
cahvc
cahvc                  ----- overlap  -----
cahvc
cahv      t = sqrt(aa1)
cahv      x0=ax
cahv      y0=ay
cahv      z0=az
cahv      do 370 j=1,ljtmod
cahv      nj=j
cahv      do 370 i=1,lit
cahv      ni=i
cahv      call sxyz
cahv      xs(i,j)=xint*t
cahv      ys(i,j)=yint*t
cahv      zs(i,j)=zint*t
cahv  370 continue
cahvc
cahvc
cahv      ij=0
cahv      do 390 i=mini,maxi
cahv      ix=ijx(i)
cahv      iy=ijy(i)
cahv      iz=ijz(i)
cahv      jmax=maxj
cahv      if(iandj) jmax=i
cahv      do 380 j=minj,jmax
cahv      jx=ijx(j)
cahv      jy=ijy(j)
cahv      jz=ijz(j)
cahv      ij=ij+1
cahv      dum =xs(ix,jx)*ys(iy,jy)*zs(iz,jz)
cahv       s(ij)= s(ij)+ dum*dij(ij)
cahv  380 continue
cahv  390 continue
cahvc
cahv 6000 continue
cahv 7000 continue
c
c     ----- find center for charge distribution -----
c
      max=maxj
      nn=0
      do 7700 i=mini,maxi
        li=loci+i
        in=ia(li)
        if(iandj) max=i
        do 7650 j=minj,max
          lj=locj+j
          jn=lj+in
          nn=nn+1
          if (iexpas .eq. -1) then
            if (onec) then
              iexp = iat
            else
              iexp = icch
            endif
            goto 7660
          endif
          if(abs(s(nn)) .le. tols .or. onetwo) then
c
c      -----  (overlap is small), centre is placed at middle of
c             originating atoms
c
            ctrx = pt5*(c(1,iat)+c(1,jat)) - cm(1)
            ctry = pt5*(c(2,iat)+c(2,jat)) - cm(2)
            ctrz = pt5*(c(3,iat)+c(3,jat)) - cm(3)
c
          else
c
c      -----  centre is located at dipole/overlap
c
            dum=one/s(nn)
            sign=one
            dovl= abs(ovl(jn))
            if(dovl.gt.zero) sign=dovl/ovl(jn)
            ctrx=dipx(jn)*dum*sign
            ctry=dipy(jn)*dum*sign
            ctrz=dipz(jn)*dum*sign
c
          endif
c
          if (each) then
c
c      -----  assign to each overlap distribution its own centre
c
c      -----  first check if overlap distribution coincides with
c             an already defined centre
c
            do 7800, iex = 1, nexp
              dist2 = (xexp(1,iex)-ctrx)**2 + (xexp(2,iex)-ctry)**2
     1               +(xexp(3,iex)-ctrz)**2
              if (dist2 .le. told3) then
                iexp = iex
                goto 7810
              endif
 7800       continue
c
c      -----  add new expansion centre
c
            nexp = nexp + 1
            xexp(1,nexp) = ctrx
            xexp(2,nexp) = ctry
            xexp(3,nexp) = ctrz
            iexp = nexp
c
 7810       continue
c
          else
c
c      -----  find closest expansion center
c
            nclos = 0
            dist=sqrt((ctrx-xexp(1,1))**2+
     1       (ctry-xexp(2,1))**2+
     2       (ctrz-xexp(3,1))**2)
            rmin=dist
            iexp=1
c
            do 7630 npnt=2,nexp
              dist=sqrt((ctrx-xexp(1,npnt))**2+
     1       (ctry-xexp(2,npnt))**2+
     2       (ctrz-xexp(3,npnt))**2)
              diff = dist - rmin
              if (abs(diff) .le. told1) nclos = nclos + 1
              if(diff .gt. told1) goto 7630
              rlast=rmin
              rmin=dist
              iexp=npnt
              if (rmin-rlast .lt. -told1) nclos = 0
 7630       continue
            repeat = nclos .ne. 0
            if (repeat) then
c           if (repeat .and. .not. onec) then
c
c        -----  two or more expansion centra are about equally
c               distant from the centre of the overlap distribution
c               create a new one if defnew = .true.
c
              if (defnew) then
                nexp = nexp + 1
                xexp(1,nexp) = ctrx
                xexp(2,nexp) = ctry
                xexp(3,nexp) = ctrz
                iexp = nexp
              else if (iexpas .eq. 0) then
c
c          -----  assign ambiguous distribution to centre of charge
c
                iexp = icch
              endif
            endif
c
c      -----  one-centre overlap distributions are assigned to the
c             origin of the basis functions
c
c           if(onec) iexp=iat
          endif
c
          if (nambpt(katom(ii)) .ne. 0) then
            iexp = katom(ii)
          endif
          if (nambpt(katom(jj)) .ne. 0) then
            iexp = katom(jj)
          endif
c
 7660     iexpc(jn)=iexp
          if (out) then
            write(6,9966) li,lj,dum,ctrx,ctry,ctrz,iexp
 9966       format(2i4,4e15.6,i4)
          endif
c
 7650   continue
 7700 continue
c
 8000 continue
 9000 continue
c
      else
c
c  -----  fit procedure to assign expansion centra to overlap
c         distributions
c
        call fitexpc(nfit,xexf,nexp,xexp,ovl,dipx,dipy,dipz,
     1               iexpc,elpot,delpot,icch,asscen)
      endif
c
c-----  transform -xexp- to global origin
c
      do 9100 i=1,nexp
        do 9100 l=1,3
           xexp(l,i)=xexp(l,i)+cm(l)
 9100 continue
      if (out)  call hatout(cm  ,3,1   ,2,'cm_eind ')
      if (out)  call hatout(xexp,3,nexp,2,'xexpglob')
c
c-----  write -xexp- to -da10- on record -45-
c
      call dawrit(idafh,ioda,xexp,3*nexp,45,navh)
c
c-----  write -iexpc- to da10 on record -46-
c
      call dawrit(idafh,ioda,iexpc,num2,46,navh)
c
      if(some) write(iwr,9998)
      ntim=0
      if(some) ntim=1
      call texit(ntim,ntim)
      return
 9998 format(' ...... end of assignment  ......')
 9997 format(' in -stvint- the rys quadrature is not implemented',
     1       ' beyond -nroots- = ',i2,/,
     2       ' lit,ljt,nroots= ',3i3)
      end
      subroutine fitexpc(npt,xyzpt,nexpc,xexpc,ovl,dipx,dipy,dipz,
     1                  iexpc,elpot,delpot,icch,asscen)
c------
c      in this routine expansion centra are assigned to overlap
c      distributions on the basis of a least-squares fit
c      to the potential generated by the overlap distributions
c      at certain points (many options), compared to the potential
c      generated at those points by the overla and dipole moments
c      of the charge distribution placed at the expansion centra
c-------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy arguments
c
      dimension xexpc(3,nexpc), xyzpt(3,npt)
      dimension ovl(nx),dipx(nx),dipy(nx),dipz(nx)
      dimension iexpc(nx)
      dimension elpot(npt,225), delpot(nexpc,225)
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/opt)
INCLUDE(../m4/common/nshel)
INCLUDE(comdrf/rys)
INCLUDE(comdrf/stv)
INCLUDE(comdrf/bas)
INCLUDE(comdrf/ijpair)
c
c-----  local variables
c
      logical asscen
      logical sameat
      logical norm,double
      logical out
      dimension xv(5,5,5),yv(5,5,5),zv(5,5,5)
      dimension ijx(35),ijy(35),ijz(35)
      dimension dij(225)
c
c-----  data statements
c
      data zero  /0.0d+00/
      data one   /1.0d+00/
      data pi212 /1.1283791670955d+00/
      data rln10 /2.30258d+00/
      data sqrt3 /1.73205080756888d+00/
      data sqrt5 /2.23606797749979d+00/
      data sqrt7 /2.64575131106459d+00/
      data ijx    / 1, 2, 1, 1, 3, 1, 1, 2, 2, 1,
     1              4, 1, 1, 3, 3, 2, 1, 2, 1, 2,
     2              5, 1, 1, 4, 4, 2, 1, 2, 1, 3,
     3              3, 1, 3, 2, 2/
      data ijy    / 1, 1, 2, 1, 1, 3, 1, 2, 1, 2,
     1              1, 4, 1, 2, 1, 3, 3, 1, 2, 2,
     2              1, 5, 1, 2, 1, 4, 4, 1, 2, 3,
     3              1, 3, 2, 3, 2/
      data ijz    / 1, 1, 1, 2, 1, 1, 3, 1, 2, 2,
     1              1, 1, 4, 1, 2, 1, 2, 3, 3, 2,
     2              1, 1, 5, 1, 2, 1, 2, 4, 4, 1,
     3              3, 3, 2, 2, 3/
c
c-----  begin
c
      out=nprint.eq.6
      tol=rln10*itol
      norm=normf.ne.1.or.normp.ne.1
c
c     ----- ishell -----
c
      do 9000 ii=1,nshell
      i=katom(ii)
      iatom = i
      xi=c(1,i)
      yi=c(2,i)
      zi=c(3,i)
      i1=kstart(ii)
      i2=i1+kng(ii)-1
      lit=ktype(ii)
      mini=kmin(ii)
      maxi=kmax(ii)
      loci=kloc(ii)-mini
c
c     ----- jshell -----
c
      do 8000 jj=1,ii
      j=katom(jj)
      jatom = j
      xj=c(1,j)
      yj=c(2,j)
      zj=c(3,j)
      j1=kstart(jj)
      j2=j1+kng(jj)-1
      ljt=ktype(jj)
      minj=kmin(jj)
      maxj=kmax(jj)
      locj=kloc(jj)-minj
c
      iandj=ii.eq.jj
c     sameat = iatom .eq. jatom
      sameat = .false.
c
c-----  one-centre overlap distributions are always assigned
c       to the atomic centre of its origin
c
      if (sameat) goto 7999
c
      call clear(elpot(1,1),npt*225)
      call clear(delpot(1,1),nexpc*225)
c
      rr=(xi-xj)**2+(yi-yj)**2+(zi-zj)**2
      nroots=(lit+ljt-2)/2+1
c
      ij=0
      do 100 i=mini,maxi
      jmax=maxj
      if(iandj) jmax=i
      do 100 j=minj,jmax
      ij=ij+1
  100 continue
c
c     ----- i primitive -----
c
      do 7000 ig=i1,i2
      ai=ex(ig)
      arri=ai*rr
      axi=ai*xi
      ayi=ai*yi
      azi=ai*zi
      csi=cs(ig)
      cpi=cp(ig)
      cdi=cd(ig)
      cfi=cf(ig)
cmw      cgi=cg(ig)
c
c     ----- j primitive -----
c
      jgmax=j2
      if(iandj) jgmax=ig
      do 6000 jg=j1,jgmax
      aj=ex(jg)
      aa=ai+aj
      aa1=one/aa
      dum=aj*arri*aa1
      if(dum.gt.tol) go to 6000
      fac= exp(-dum)
      csj=cs(jg)
      cpj=cp(jg)
      cdj=cd(jg)
      cfj=cf(jg)
cmw      cgj=cg(jg)
      ax=(axi+aj*xj)*aa1
      ay=(ayi+aj*yj)*aa1
      az=(azi+aj*zj)*aa1
c
c     ----- density factor -----
c
      double=iandj.and.ig.ne.jg
      ij=0
      do 360 i=mini,maxi
      go to (110,120,220,220,130,220,220,140,220,220,
     1       150,220,220,160,220,220,220,220,220,170,
     2       180,220,220,190,220,220,220,220,220,200,
     3       220,220,210,220,220),i
  110 dum1=csi*fac
      go to 220
  120 dum1=cpi*fac
      go to 220
  130 dum1=cdi*fac
      go to 220
  140 if(norm) dum1=dum1*sqrt3
      go to 220
  150 dum1=cfi*fac
      go to 220
  160 if(norm) dum1=dum1*sqrt5
      go to 220
  170 if(norm) dum1=dum1*sqrt3
      go to 220
cmw  180 dum1=cgi*fac
  180 go to 220
  190 if(norm) dum1=dum1*sqrt7
      go to 220
  200 if(norm) dum1=dum1*sqrt5/sqrt3
      go to 220
  210 if(norm) dum1=dum1*sqrt3
  220 continue
c
      jmax=maxj
      if(iandj) jmax=i
      do 360 j=minj,jmax
      go to (230,250,350,350,260,350,350,270,350,350,
     1       280,350,350,290,350,350,350,350,350,300,
     2       310,350,350,320,350,350,350,350,350,330,
     3       350,350,340,350,350),j
  230 dum2=dum1*csj
      if(.not.double) go to 350
      if(i.gt.1) go to 240
      dum2=dum2+dum2
      go to 350
  240 dum2=dum2+csi*cpj*fac
      go to 350
  250 dum2=dum1*cpj
      if(double) dum2=dum2+dum2
      go to 350
  260 dum2=dum1*cdj
      if(double) dum2=dum2+dum2
      go to 350
  270 if(norm) dum2=dum2*sqrt3
      go to 350
  280 dum2=dum1*cfj
      if(double) dum2=dum2+dum2
      go to 350
  290 if(norm) dum2=dum2*sqrt5
      go to 350
  300 if(norm) dum2=dum2*sqrt3
      go to 350
cmw  310 dum2=dum1*cgj
  310 if(double) dum2=dum2+dum2
      go to 350
  320 if(norm) dum2=dum2*sqrt7
      go to 350
  330 if(norm) dum2=dum2*sqrt5/sqrt3
      go to 350
  340 if(norm) dum2=dum2*sqrt3
  350 continue
c
      ij=ij+1
  360 dij(ij)=dum2
c
c     ----- electrostatic potential -----
c
      aax=aa*ax
      aay=aa*ay
      aaz=aa*az
c
c-----  loop over measuring points
c
      do 500 ipt=1,npt
        znuc=one
        cx=xyzpt(1,ipt)
        cy=xyzpt(2,ipt)
        cz=xyzpt(3,ipt)
        xx=aa*((ax-cx)**2+(ay-cy)**2+(az-cz)**2)
        if(nroots.le.3) call rt123
        if(nroots.eq.4) call roots4
        if(nroots.eq.5) call roots5
c
c  -----  loop over roots
c
        do 420 iroot=1,nroots
          uu=u(iroot)*aa
          ww=w(iroot)*znuc
          tt=one/(aa+uu)
          t= sqrt(tt)
          x0=(aax+uu*cx)*tt
          y0=(aay+uu*cy)*tt
          z0=(aaz+uu*cz)*tt
          do 410 j=1,ljt
            nj=j
            do 410 i=1,lit
              ni=i
              call sxyz
              xv(i,j,iroot)=xint
              yv(i,j,iroot)=yint
              zv(i,j,iroot)=zint*ww
  410     continue
  420   continue
c
        ij=0
        do 450 i=mini,maxi
          ix=ijx(i)
          iy=ijy(i)
          iz=ijz(i)
          jmax=maxj
          if(iandj) jmax=i
          do 440 j=minj,jmax
            jx=ijx(j)
            jy=ijy(j)
            jz=ijz(j)
            dum=zero
            do 430 iroot=1,nroots
  430 dum=dum+xv(ix,jx,iroot)*yv(iy,jy,iroot)*zv(iz,jz,iroot)
            dum=dum*(aa1*pi212)
            ij=ij+1
            dum=dum*dij(ij)
c
c      -----  collect primitive contributions to potential in -ipt-
c
            elpot(ipt,ij) = elpot(ipt,ij) + dum
c
  440     continue
  450   continue
c
  500 continue
c
c-----  end of loop over primitives
c
 6000 continue
 7000 continue
c
c-----  find best fit, by least squares procedure
c
      ij=0
      do 436 i=mini,maxi
        jmax = maxj
        if(iandj) jmax=i
        do 437 j=minj,jmax
          ij=ij+1
          nij=ia(loci+i)+locj+j
          do 438 ipt = 1, npt
            do 439 jpt=1,nexpc
              dist=
     1    (xyzpt(1,ipt)-xexpc(1,jpt))**2+
     1    (xyzpt(2,ipt)-xexpc(2,jpt))**2+
     1    (xyzpt(3,ipt)-xexpc(3,jpt))**2
              if(dist.ne.zero) then
                dmin2=one/dist
                dmind1=sqrt(dmin2)
c
                elexp=(ovl(nij)+
     1         (dipx(nij)*(xyzpt(1,ipt)-xexpc(1,jpt))+
     1          dipy(nij)*(xyzpt(2,ipt)-xexpc(2,jpt))+
     1          dipz(nij)*(xyzpt(3,ipt)-xexpc(3,jpt)))*dmin2)*dmind1
                delpot(jpt,ij)=delpot(jpt,ij)+(elpot(ipt,ij)-elexp)**2
              endif
  439       continue
  438     continue
  437   continue
  436 continue
c
c-----  select centre that reproduces potential best
c       one-centre overlap distributions are assigned to that centre
c
 7999 continue
      ij=0
      do 600 i=mini,maxi
        jmax = maxj
        if(iandj) jmax=i
        do 550 j=minj,jmax
          ij=ij+1
          nij=ia(loci+i)+locj+j
          if (sameat) then
            iexpc(nij) = iatom
            goto 550
          endif
          small = 1.d20
          nclos = 0
          do 540 jpt=1,nexpc
            diff=delpot(jpt,ij)-small
            if (diff .le. zero) then
              iexpc(nij)=jpt
              small = delpot(jpt,ij)
              if (diff .lt. -1.d-06) nclos = 0
            endif
            if(abs(diff) .le. 1.d-06) nclos = nclos + 1
  540     continue
          if (nclos .gt. 0) then
              write(iwr,*)
     1       'possibly more acceptable expansion centers for ',nij
            if (asscen) then
              iexpc(nij) = icch
            endif
          endif
  550   continue
  600 continue
c
c-----  end of loop over shells
c
 8000 continue
 9000 continue
c
      return
      end
_ENDIF
      subroutine dippope(nexpc,nexpx,cexp,xexp,iexp,a,b,q,w,qdp,is)
c------
c      calculates dp charges
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy variables
c
      dimension cexp(3,nexpc), xexp(3,nexpx), q(nexpc,4)
      dimension iexp(nx), is(nexpx)
      dimension a(nx), b(nx), w(*)
      dimension qdp(nexpx)
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
      common /restar/ nprint
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/opt)
INCLUDE(comdrf/scfopt)
INCLUDE(comdrf/mollab)
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/drfdaf)
c
INCLUDE(comdrf/runpar)
c
c-----  local variables
c
      dimension imat(4)
      dimension sum(4)
      logical out
c
      data one,two /1.0d00,2.0d00/
      data imat /53,54,55,12/
c
c-----  begin
c
      noprt = 1
c
      out =noprt.eq.1.and.nprint.eq.3
c
c-----  get density in array b
c
      call daread(idafh,ioda,b,nx,16)
      if(scftyp.eq.'uhf') then
c
c  -----  add beta density if uhf wave function
c
        call daread(idafh,ioda,a,nx,20)
        do 10 l=1,nx
          b(l)=b(l)+a(l)
   10   continue
      endif
c
c-----  loop over x,y,z dipoles and overlap of charge distributions
c
      do 150 l=1,4
c
c  -----  read x,y,z or s into array a
c
        call daread(idafh,ioda,a,nx,imat(l))
c
c  -----  loop over charge distributions
c
        ij = 0
        do 140 i=1,num
          do 130 j=1,i
            if(i.eq.j) then
              t=one
            else
              t=two
            endif
            ij=ij+1
            a(ij)=a(ij)*b(ij)*t
  130     continue
  140   continue
c
c  -----  condense contributions of charge distributions
c
c       call condnse(nexpc,a,q(1,l),iexp,1.,sum(l))
        call condnse(nexpc,a,q(1,l),iexp,one,sum(l))
  150 continue
      if (out) call hatout(q,nexpc,4,5,'dip_q_exp')
c
c-----  rearrange dipole moments for tdpop
c
      nn=0
      do 160 i=1,nexpc
        do 160 k=1,3
          nn=nn+1
  160     a(nn)=q(i,k)
c
c-----  calculate dp charges
c
      call tdpope(cexp,xexp,a,q(1,4),w,qdp,is)
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,260) sum(4)
  260   format(//t20,'total number of electrons'  ,f10.3/)
      endif
c
      return
      end
      subroutine condnse(nexp,d,q,iexp,oc,sum)
c------
c  * * * condenses (inter) orbital distributions 'd' to
c  * * * one centre distributions 'q' in -nexp- expansion centers
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy variables
c
      dimension d(nx), q(nexp)
      dimension iexp(nx)
c
c-----  common blocks
c
INCLUDE(../m4/common/infoa)
c
c-----  data statements
c
      data zero,pt5/0.0d00,0.5d00/
c
      sum=zero
      do 10, ij = 1, nx
        del=oc*d(ij)
        sum=sum+del
        q(iexp(ij))=q(iexp(ij))+del
   10 continue
c
      return
      end
      subroutine tdpope(cexp,xexp,p,q,w,qdp,isign)
c------
c         population analysis on occupied orbitals preserving the
c         dipole moment
c
c         input parameters
c         nexpc: number of expansion centers
c         p(3,nexpc) gross mulliken electronic dipoles
c         czan(nat) nuclear charges
c         q(nexpc) : mulliken gross atomic charges
c
c         output parameters
c         qdp(nexpx) : effective point charges conserving molecular
c         charge and dipole moment
c
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      parameter (nnam=1024)
c
c-----  dummy variables
c
      dimension cexp(3,nexpc), p(3,nexpc)
      dimension xexp(3,nexpx)
      dimension q(nexpc), w(*)
      dimension qdp(nexpx)
      dimension isign(nexpx)
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/mollab)
c
INCLUDE(comdrf/elpinf)
INCLUDE(comdrf/expan)
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/drfdaf)
c
INCLUDE(comdrf/runpar)
c
c-----  local variables
c
      character*16 names(nnam)
      character*80 text
      character *8 errmsg(3)
c
c-----  data statements
c
      data zero,small/0.0d00,1.d-4/
      data errmsg /'program', 'stop in', '-tdpope-'/
c
c-----  begin
c
c-----  check on length of names array
c
      if (nexpc .gt. nnam) then
        write(iwr,1000) nexpc
 1000   format(/,'  too many expansion centra defined for overlap',
     1  ' distributions: ',/,' -----  enlarge nnam in tdpope ',
     2  ' to at least ',i4)
        call hnderr(3,errmsg)
      endif
c
c-----  mulliken analysis
c
      call clear(w,6)
      ctot=zero
c
      do  6 i=1,nexpc
        if(i.le.nat) then
          names(i)=anam(i)//bnam(i)
          zz=czan(i)
        else if (icnexp .lt. 0 .or. icnexp .eq. 7
     1           .or. iexpas .eq. -3) then
          write(names(i),1001) ' cent ', i
 1001     format(a8,i4)
          zz=zero
        else
          names(i)=expnam(i-nat)
          zz=zero
        endif
c
c  -----  only "charge free" dipoles are redistributed
c
        do 4 l=1,3
          p(l,i)=q(i)*cexp(l,i)-p(l,i)
    4   continue
        q(i)=zz-q(i)
        ctot=ctot+q(i)
        do 5 l=1,3
          w(l)=w(l)+q(i)*cexp(l,i)
          w(l+3)=w(l+3)+p(l,i)
    5   continue
    6 continue
c
c-----  save mulliken charges and dipoles
c
      call dawrit (idafdrf,iodadrf,cexp,3*nexpc,102,navdrf)
c
c-----  output mulliken charges and dipoles
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,10)
   10   format(//t20,22('-')/t20,'gross mulliken charges'/
     1 t20,22('-')/)
      endif
c
      call printq(2,nexpc,q,cexp,names)
c
      if(abs(ctot).ge.small) then
        do 15 l=1,3
          w(l)=w(l)/ctot
   15   continue
        if ((.not. mcupdt) .or. (imcout .eq. 5)) then
          write(iwr,16)
   16     format(//t20,26('-')/t20,'center of mulliken charges'/
     1  t20,26('-')/)
          call hatout(w,1,3,2,' ')
          write(iwr,17)
   17     format(//t20,25('-')/t20,'charge free dipole moment'/
     1  t20,25('-')/)
          call hatout(w(4),1,3,2,' ')
        endif
      endif
c
c-----  punch mulliken charges on ipnch
c
      write(ipnch,*) title
      write(ipnch,*) 'expanded'
      write(ipnch,*)'  name, charge, x, y, z'
      write(ipnch,*)' $mul-charges'
      do 20  i=1,nexpc
        write(ipnch,650) names(i),q(i),(cexp(k,i),k=1,3)
   20 continue
      write(ipnch,*) ' $end'
c
c-----  write mulliken charges on -da31-, record -116-
c
      nchrp(7) = nexpc
      ichrp(7) = 102
      nchrp(8) = nexpc
      ichrp(8) = 102
      nchrp(9) = nexpc
      ichrp(9) = 102
c     call dawrit(idafdrf,iodadrf,q,nexpc,116,navdrf)
      call dawrit(idafdrf,iodadrf,q,nexpc,ilmc,navdrf)
c
c-----  punch mulliken dipoles
c
      write(ipnch,*)'  name, dipx,dipy,dipz, x, y, z'
      write(ipnch,*)' $mul-dipoles'
      do 30  i=1,nexpc
        write(ipnch,650) names(i),(p(l,i),l=1,3),(cexp(k,i),k=1,3)
   30 continue
      write(ipnch,*) ' $end'
c
c-----  write mulliken dipoles on -da31-, record -117-
c
c     call dawrit(idafdrf,iodadrf,p,3*nexpc,117,navdrf)
      call dawrit(idafdrf,iodadrf,p,3*nexpc,ilmd,navdrf)
c
c-----  define overall expansion centra
c
      iexpx = 0
c
c-----  check if atomic centra are required as expansion centra
c
      if (iexpcn .le. 3) then
c
c  -----  atomic centra
c
        do 2100, i = 1, nat
          do 2200, k= 1, 3
            xexp(k,i) = c(k,i)
 2200     continue
 2100   continue
c
        iexpx = iexpx + nat
      endif
c
c-----  check if centre of charge is required as expansion centre
c
      if (iexpcn .eq. 1 .or. iexpcn .eq. 2 .or.
     1      iexpcn .eq. 4 .or. iexpcn .eq. 5) then
c
        call drfcm(xexp(1,iexpx+1))
        iexpx = iexpx + 1
      endif
c
c-----  read expansion centra from input if required
c       (data block beginning with $expx)
c
      if (iexpcn .eq. 2 .or. iexpcn .eq. 3 .or.
     1      iexpcn .eq. 5 .or. iexpcn .eq. 6) then
        rewind(ir)
  110   read(ir,1100,end=98) text
 1100   format(a80)
        if (text(:6) .ne. ' $expx') goto 110
c
  120   read(ir,1100) text
        if (text(:5) .eq. ' $end') goto 130
c
        iexpx = iexpx + 1
        read(text,1300) names(iexpx), (xexp(k,iexpx), k= 1,3)
 1300   format(a10,3f20.10)
        do 125, k = 1, 3
          xexp(k,iexpx) = xexp(k,iexpx)
  125   continue
        goto 120
c
   98   write(iwr,*)' list $expx not found on input file, ',
     1               'please check'
        call hnderr(3,errmsg)
  130   continue
      endif
c
      if (iexpcn .eq. 7 .and. icnexp .eq. 7) then
c
c  -----  expansion centra for overlap distributions are
c         also used to expand dp charges
c
        do 2400, i = 1, nexpc
          do 2500, k = 1, 3
            xexp(k,i) = cexp(k,i)
 2500     continue
 2400   continue
      endif
c
      call dpopane(nexpc,nexpx,cexp,xexp,q,p,w,qdp,isign)
c
c-----  printed output of td charges
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,500)
  500   format(
     1//t20,36('-'),/t20,'charges preserving the dipole moment',
     2/t20,36('-'))
      endif
c
      call printq(2,nexpx,qdp,xexp,names)
c
c-----  punch charges on internal points
c
      write(ipnch,550)
  550 format('----  dipole conserving charges  ------'/)
      write(ipnch,*)'  name, charge, x, y, z'
      write(ipnch,*)' $dp-charges'
      do 600 i=1,nexpx
        write(ipnch,650) names(i),qdp(i),(xexp(k,i),k=1,3)
  600 continue
      write(ipnch,*) ' $end'
  650 format(a10,6f10.6)
c
c-----  write dipole preserving charges on -da31-, record -119-
c
      nchrp(10) = nexpx
      ichrp(10) = 103
      call dawrit (idafdrf,iodadrf,xexp,3*nexpx,103,navdrf)
c     call dawrit(idafdrf,iodadrf,qdp,nexpx,119,navdrf)
      call dawrit(idafdrf,iodadrf,qdp,nexpx,ildc,navdrf)
c
      return
      end
      subroutine dpopane(ndip,npnts,cp,cq,q,p,w,qdp,isign)
c------
c      --------  p.th. van duijnen, ibm-kingston 1985 -----
c
c     ndip = number of dipole moments
c     npnts= number of expansion points
c     cp   = coordinates of dipoles
c     cq   = coordinates of expansion centers
c     q    = charges(input)
c     p    = dipoles
c     w    = work space
c     qdp  = charges(output)
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      dimension cp(3,ndip),q(ndip),p(3,ndip),w(*)
      dimension cq(3,npnts)
      dimension isign(npnts)
      dimension qdp(npnts)
c
      common/iofile/ir,iw,ipnch
c
      dimension ri(3),ar(3),br(3),cr(3),dr(3),b(3,3),xav(3)
      dimension bvec(3,3),ia(3)
      dimension ib(3)
c
      data ia/0,1,3/
      data zero,one/0.d00,1.d00/
      data thresh,smallw/1.0d-05,1.0d-10/
c
      weight(x)= exp(-x**2)
c
c-----  begin
c
c-----  initialize dp charges
c
      call clear(qdp,npnts)
c
c-----  loop over the muliken charges and dipoles
c
      do 400 i=1,ndip
c
c  -----  position vector in ar
c
        ar(1)=cp(1,i)
        ar(2)=cp(2,i)
        ar(3)=cp(3,i)
c
c  -----  bl is used for scaling the weight function
c
        bl=10000000.0d0
        do 15 l=1,npnts
          call distab(ar,cq(1,l),br,bll)
          if(bll.lt.bl.and.bll.gt.thresh) bl=bll
   15   continue
c
c  -----  loop over expansion points for finding averages etc.
c
        nsign=0
        sum=zero
        call clear(xav,3)
        call clear(b,9)
c
        do 35 l=1,npnts
c
c    -----  position vector in ri
c
          do 20 k=1,3
            ri(k)=cq(k,l)
   20     continue
c
c    -----  distance to dipole(i) into cr
c
          call distab(ri,ar,cr,al)
c
c    -----  weighting function
c
          wl=weight(al/bl)
c
c         if (wl .gt. small) then
c
            nsign=nsign+1
            isign(nsign)=l
            w(nsign)=wl
            sum=sum+wl
            call accum (ri,xav,wl,3)
c
c    -----  update matrix b
c
            do 30 im=1,3
              do 30 jm=1,3
                b(im,jm)=b(im,jm)+ri(im)*ri(jm)*wl
   30       continue
c
c         endif
c
   35   continue
c
c       write(iwr,*) 'nsign = ',nsign,(isign(ii),ii=1,nsign)
c       write(iwr,*) 'w = ',(w(ii),ii=1,nsign)
c
c  -----  average coordinates in xav
c
        fact=one/sum
        do 36 im=1,3
          xav(im)=xav(im)*fact
   36   continue
c
c  -----  complete matrix b
c
        do 38 im=1,3
          do 38 jm=1,3
            b(im,jm)=b(im,jm)*fact-xav(im)*xav(jm)
   38   continue
c
c  -----  diagonalize matrix b
c
        call clear(cr,3)
        call shrink(b,b,3)
c       call diagiv(b,bvec,cr,ia,3,3,3)
        call gldiag(3,3,3,b,ib,cr,bvec,ia,2)
c
c  -----  first redistribute the charge and update charge-free
c         dipole resulting from shifting the charge
c
        do 60 l=1,nsign
          ll=isign(l)
c
c    -----  position of point l relative to centre
c
c         do 55 k=1,3
c           ri(k)=cq(k,ll)-xav(k)
c  55     continue
          do 55 k=1,3
            ri(k)=cq(k,ll)-cp(k,i)
   55     continue
c
c    -----  charge on atom l
c
          qad=w(ll)*fact*q(i)
          qdp(ll)=qdp(ll)+qad
c
c    -----  correction to dipole at -i-
c
          do 56, k = 1, 3
            p(k,i) = p(k,i) - qad*ri(k)
   56     continue
c
   60   continue
c
c  -----  charge-free dipole in dr
c
        do 140 l=1,3
          dr(l)=-p(l,i)
  140   continue
c
c  -----  transform dipole vector
c
        call matvec(bvec,dr,ar,3,.true.)
c
c  -----  form u(dag)(p-q<x>)
c
        do 150 im=1,3
          dr(im)=ar(im)/(cr(im)+thresh*(cr(3)+thresh))
  150   continue
c
c  -----  transform result to br
c
        call matvec(bvec,dr,br,3,.false.)
c
c  -----  loop  over significant points and compute partial charges
c
        do 160 l=1,nsign
          ll=isign(l)
c
c    -----  position of point l relative to centre
c
          do 155 k=1,3
            ri(k)=cq(k,ll)-xav(k)
  155     continue
c
c    -----  charge on atom l
c
          qad=w(ll)*fact*ddot(3,br,1,ri,1)
c         qad=w(ll)*fact*adotb(br,ri,3)
          qdp(ll)=qdp(ll)-qad
  160   continue
  400 continue
      return
      end
_IF()
      subroutine qppop(itdist)
c------
c      sets memory partitioning for standard mulliken and
c      quadrupole preserving charge analysis with equal partitioning
c      of overlap distribution contributions between originating
c      centres
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      logical itdist
c
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/scm)
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/qpanl)
c
INCLUDE(comdrf/cenmas)
INCLUDE(comdrf/drfdaf)
c
      data zero /0.0d00/
c
c-----  begin
c-----  calculate second moment integrals w.r.t. centre of mass
c
      call qdpint(xscm(1),xscm(1+nx),xscm(1+2*nx),xscm(1+3*nx),
     1            xscm(1+4*nx),xscm(1+5*nx),cenms,num)
c
c-----  save second moment integrals on da10
c
      call dawrit(idafh,ioda,xscm(1),nx,47,navh)
      call dawrit(idafh,ioda,xscm(1+nx),nx,48,navh)
      call dawrit(idafh,ioda,xscm(1+2*nx),nx,49,navh)
      call dawrit(idafh,ioda,xscm(1+3*nx),nx,50,navh)
      call dawrit(idafh,ioda,xscm(1+4*nx),nx,51,navh)
      call dawrit(idafh,ioda,xscm(1+5*nx),nx,52,navh)
c
      i10 = 1
      i20 = i10 + max(nx,nat*10) + 1
      i30 = i20 + nx + 1
      i40 = i30 + nat*10 + 1
      i50 = i40 + (nat*(nat+1)/2)*10 + 1
      i60 = i50 + 7*nat*3 + 1
      last = i60 + 7*nat + 1
      call setc(last)
c
      call quppop(itdist,xscm(i10),xscm(i20),xscm(i30),xscm(i40),
     1                   xscm(i50),xscm(i60))
c
      return
      end
      subroutine quppop(itdist,a,b,q,d,ce,qe)
c------
c      perform quadrupole preserving analysis, based on equal partitioni
c      of overlap distributions contributions between originating
c      centres
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy arrays
c
      logical itdist
c
      dimension a(nx), b(nx)
      dimension q(nat,10), d(nat*(nat+1)/2,10)
      dimension ce(3,7*nat)
      dimension qe(7*nat)
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(comdrf/ijpair)
INCLUDE(../m4/common/nshel)
      common /restar/ nprint
INCLUDE(comdrf/mollab)
INCLUDE(comdrf/scfopt)
INCLUDE(comdrf/nmorb)
INCLUDE(comdrf/opt)
INCLUDE(comdrf/auxdrf)
c
INCLUDE(comdrf/qpanl)
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/drfdaf)
c
INCLUDE(comdrf/runpar)
c
c-----  local variables
c
      dimension sum(10)
      dimension imat(10)
      logical out, mcout
c
c-----  data statements
c                s  x  y  z  xx xy yy xz yz zz
c
      data imat /12,53,54,55,47,50,48,51,52,49/
c
c-----  begin
c
      out = nprint .eq. 3
c
      mcout = ((.not. mcupdt) .or. (imcout .eq. 5))
c
      if (mcout) then
        write(iwr,1001)
 1001   format(//t20,22('-')/t20,' qp analysis'/
     1 t20,22('-')/)
      endif
c
c-----  assign overlap distributions
c
      call lookupd
c
c-----  read density
c
      call daread(idafh,ioda,b,nx,16)
      if(scftyp.eq.'uhf') then
        call daread(idafh,ioda,a,nx,20)
        do 10 l=1,nx
          b(l)=b(l)+a(l)
   10 continue
      endif
c
c-----  loop over overlap, x,y,z dipole moments,
c       xx,yy,zz,xy,xz and yz quadrupole moments of distributions
c
      do 150, l = 1, 10
c
c  -----  read s, x, y, z, xx, xy, yy, xz, yz, zz
c
        call daread(idafh,ioda,a,nx,imat(l))
c
c  -----  set up loop over charge distributions
c
        ij=0
        do 140 i=1,num
          do 130 j=1,i
            if(i.eq.j) then
              t=1.0d0
            else
              t=2.0d0
            endif
            ij=ij+1
            a(ij)=a(ij)*b(ij)*t
  130     continue
  140   continue
c
c  -----  contract charges, dipoles and quadrupoles into
c         mulliken charges, dipoles and quadrupoles
c
c       call condns(num,nat,a,d(1,l),q(1,l),icent,1.,sum(l))
        call condns(num,nat,a,d(1,l),q(1,l),icent,1.d00,sum(l))
c
  150 continue
c
      if (out) call hatout(q,nat,10,5,'dip_q')
c
c-----  prepare dipoles and quadrupoles for qdpop
c
      nmd = nat
      nmq = 4*nat
      nnd = 0
      nnq = 0
      do 200, l = 1, nat
        a(l) = q(l,1)
        do 190, im = 1, 3
          nnd = nnd + 1
          a(nmd+nnd) = q(l,im+1)
          do 170, jm = 1, im
            ij = ia(im) + jm
            nnq = nnq + 1
            a(nmq+nnq) = q(l,ij+4)
  170     continue
  190   continue
  200 continue
c
c-----  calculate mulliken charges, dipoles and quadrupoles
c       and determine qp charges
c
      call qdpop(itdist,a(1),a(nmd+1),a(nmq+1),ce,qe,auxx)
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,260) sum(1)
  260   format(//t20,'total number of electrons'  ,f10.3/)
      endif
c
      return
      end
      subroutine qdpop(itdist,q,p,qu,ce,qe,w)
c------
c  * * *  population analysis on occupied orbitals preserving the
c  * * *  dipole moment
c
c         input parameters
c         nat: number of internal nuclei
c         q(nat) gross mulliken electronic charges
c         p(3,nat) gross mulliken electronic dipoles
c         czan(nat) nuclear charges
c
c         output parameters
c         q(nat) first: mulliken gross atomic charges
c         q(nat) second: effective point charges conserving molecular
c         charge and dipole moment
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
c-----  dummy arrays
c
      logical itdist
      dimension p(3,nat), qu(6,nat)
      dimension q(nat), w(*)
      dimension ce(3,7*nat)
      dimension qe(7*nat)
c
c-----  common blocks
c
INCLUDE(comdrf/iofil)
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/nshel)
INCLUDE(comdrf/mollab)
INCLUDE(comdrf/nmorb)
INCLUDE(comdrf/opt)
INCLUDE(comdrf/ihelp)
INCLUDE(comdrf/ijpair)
c
INCLUDE(comdrf/dafil)
c
INCLUDE(comdrf/qpanl)
INCLUDE(comdrf/elpinf)
c
INCLUDE(comdrf/cenmas)
INCLUDE(comdrf/drfdaf)
c
INCLUDE(comdrf/runpar)
      common/restar/nprint
c
c-----  local variables
c
      character*16 names(8*128)
      character*10 namec(7*3000)
      character*6 expnam
      character*4 namnum
c
      dimension qqm(3,3)
c
      dimension a(6), eig(3), ar(3), ri(3)
      dimension trf(3,3)
c
c      dimension qq(8*nat)
c      dimension cc(3,8*nat)
      dimension qq(8*3000),cc(3,8*3000)
c
      logical discard
c
c-----  data statements
c
      data zero,small,pt5,one,onept5,two,three
     1 /0.0d00,1.d-4,.5d00,1.0d00,1.5d00,2.0d00,3.0d00/
      data expnam /'centre'/
c
c-----  mulliken analysis
c
      if (nat.gt.3000) call caserr
     +('qdpop: nat>3000, increase dimensions of qq,namec and cc')
      nexc = 0
      nexc0 = 0
      call clear(w,10)
      call clear (qq,8*nat)
      ctot = zero
c
      do 1000, i = 1, nat
c 1-----
        names(i) = anam(i)//bnam(i)
c
c  -----  correct quadrupoles
c         and dipoles for charge contribution
c
        do 100, l = 1, 3
          p(l,i) = q(i)*c(l,i) - p(l,i)
  100   continue
c
        do 200, l = 1, 3
          do 150, k = 1, l
            kl = ia(l) + k
            qu(kl,i) = q(i)*(c(l,i)-cenms(l))*(c(k,i)-cenms(k))
     2               - qu(kl,i)
  150     continue
  200   continue
c
c  -----  add nuclear charge
c
        q(i) = czan(i) - q(i)
        ctot = ctot + q(i)
c
        do 300, l = 1, 3
          w(l) = w(l) + q(i)*c(l,i)
          w(l+3) = w(l+3) + p(l,i)
  300   continue
c 1-----
 1000 continue
c
c-----  calculate second moment of mulliken charges, dipoles and
c       quadrupoles
c
      if (ndppr .ge. 3) then
c 1-----
        call clear (qqm,9)
        do 2000, i = 1, nat
          do 1100, k = 1, 3
            do 1010, l = 1, k
              kl = ia(k) + l
              qqm(k,l) = qqm(k,l)
     2                 + qu(kl,i)
     3                 + p(k,i)*(c(l,i)-cenms(l))
     4                 + q(i)*(c(k,i)-cenms(k))*(c(l,i)-cenms(l))
              if (k .ne. l) qqm(l,k) = qqm(l,k)
     2                 + qu(kl,i)
     3                 + p(l,i)*(c(k,i)-cenms(k))
     4                 + q(i)*(c(l,i)-cenms(l))*(c(k,i)-cenms(k))
 1010       continue
 1100     continue
 2000   continue
c
        write(iwr,2011) ((qqm(l,k), k= 1,l), l=1,3)
 2011   format(/,' second moments wrt centre of mass',
     1          ' of up to 2nd mulliken moments, lower triangle ',/,
     2 ' qqxx = ', f10.6, ' a.u.',/
     3 ' qqxy = ', f10.6, ' a.u.',/
     4 ' qqyy = ', f10.6, ' a.u.',/
     5 ' qqxz = ', f10.6, ' a.u.',/
     6 ' qqyz = ', f10.6, ' a.u.',/
     7 ' qqzz = ', f10.6, ' a.u.')
c 1-----
      endif
c
c-----  save & output of mulliken charges, dipoles and quadrupoles
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,2021)
 2021   format(//t20,22('-')/t20,'gross mulliken charges'/
     1 t20,22('-')/)
      endif
c
      call printq(3,nat,q,c,names)
c
      if (abs(ctot).ge.small) then
c 1-----
        do 3000, l = 1, 3
          w(l) = w(l)/ctot
 3000   continue
c
        if ((.not. mcupdt) .or. (imcout .eq. 5)) then
c   2-----
          write(iwr,3011)
 3011     format(//t20,26('-')/t20,'center of mulliken charges'/
     1  t20,26('-')/)
          call hatout(w,1,3,2,' ')
c
          write(iwr,3021)
 3021     format(//t20,25('-')/t20,'charge free dipole moment'/
     1  t20,25('-')/)
          call hatout(w(4),1,3,2,' ')
c   2-----
        endif
c 1-----
      endif
c
c-----  punch mulliken charges
c
      write(ipnch,*) title
      write(ipnch,*)'  name, charge, x, y, z'
      write(ipnch,*)' $mul-charges'
      do 3100, i = 1, nat
        write(ipnch,3111) anam(i),bnam(i),q(i),(c(k,i),k=1,3)
 3100 continue
      write(ipnch,*) ' $end'
c
c-----  write mulliken charges on -da31-, record -111-
c
      call dawrit(idafdrf,iodadrf,c,3*nat,101,navdrf)
      call dawrit(idafdrf,iodadrf,q,nat,111,navdrf)
c
c-----  punch mulliken dipoles
c
      write(ipnch,*)'  name, dipx,dipy,dipz, x, y, z'
      write(ipnch,*)' $mul-dipoles'
      do 3200, i = 1, nat
        write(ipnch,3111) anam(i),bnam(i),(p(l,i),l=1,3),(c(k,i),k=1,3)
 3200 continue
      write(ipnch,*) ' $end'
c
      if (ndppr .ge. 3) call dipwrit(nat,anam,bnam,p)
c
c-----  write mulliken dipoles on -da31-, record -112-
c
      call dawrit(idafdrf,iodadrf,p,3*nat,112,navdrf)
c
c-----  write mulliken quadrupoles on -da31-, record -113-
c
      call dawrit(idafdrf,iodadrf,qu,6*nat,113,navdrf)
c
c-----  punch mulliken quadrupoles
c
      write(ipnch,*)'  name, quxx,quxy,quyy,quxz,quyz,quzz'
      write(ipnch,*)' $mul-quadrupoles'
      do 3300, i = 1, nat
        write(ipnch,3111) anam(i),bnam(i),(qu(l,i),l=1,6)
 3300 continue
c
      write(ipnch,*) ' $end'
c
      if (ndppr .ge. 3) call quawrit(nat,anam,bnam,qu)
c
c-----  calculate qp charges
c
      if (nogenxc .eq. 0) then
c 1-----
c  -----  generate extra expansion centra related to the quadrupole
c         moment to be represented
c
        write (iwr,3311)
 3311   format (/,' extra expansion centra are generated ')
c
        if (nocnstr .le. 0) nocheck = 1
c
        if (nocnstr .eq. 0) then
c   2-----
          ndipgen = 0
c
          write (iwr,3321)
 3321     format (/, ' both dipole and quadrupole moments are',
     2  ' reconstructed by charges on extra centra')
c   2-----
        endif
c
        if (nocnstr .lt. 0) then
c   2-----
          write (iwr,3331)
 3331     format (/, ' quadrupole moments are reconstructed by',
     2    ' charges on extra centra')
c
c    -----  correct for dp and mulliken charges
c
          call daread(idafdrf,iodadrf,qq,nat,114)
c
          do 3400, i = 1, nat
            do 3350, k = 1, 3
              do 3341, l = 1, k
c         5-----
                kl = ia(k) + l
c
c          -----  correct for dp charges
c
                qu(kl,i) = qu(kl,i) -
     2          qq(i)*(c(k,i)-cenms(k))*(c(l,i)-cenms(l))
c
c          -----  correct for mulliken charges
c
                qu(kl,i) = qu(kl,i) +
     2          q(i)*(c(k,i)-cenms(k))*(c(l,i)-cenms(l))
c         5-----
 3341         continue
 3350       continue
 3400     continue
c   2-----
        endif
c
        call clear (qq,8*nat)
c
        do 3500, i = 1, nat
c   2-----
c    -----  loop over mulliken centra
c
c         call copyv(c(1,i),ar,3)
          call dcopy(3,c(1,i),1,ar,1)
c
c    -----  construct mulliken dipole if required
c
          dfact = dfacmx
c
          if (ndipgen .eq. 0) then
c     3-----
            rr = sqrt(p(1,i)**2 + p(2,i)**2 + p(3,i)**2)
c
            if (nscdis .eq. 0) then
c       4-----
              dfact = one/rr
              if (dfact .gt. dfacmx) dfact = dfacmx
              if (dfact .lt. dfacmn) dfact = dfacmn
c       4-----
            endif
c
            nexc0 = nexc0 + 1
            do 3410, k = 1, 3
c       4-----
              ce(k,nexc0) = c(k,i) + p(k,i)*dfact/rr
c       4-----
 3410       continue
c     3-----
          endif
c
          if (nocnstr .eq. 0) then
c     3-----
            qq(i) = qq(i) - rr/dfact
            qe(nexc0) = rr/dfact
c
c      -----  correct quadrupole for new charges
c
            do 3430, k = 1, 3
              do 3421, l = 1, k
                kl = ia(k) + l
                qu(kl,i) = qu(kl,i) +
     2          qe(nexc0)*(c(k,i)-cenms(k))*(c(l,i)-cenms(l)) -
     3          qe(nexc0)*(ce(k,nexc0)-cenms(k))*(ce(l,nexc0)-cenms(l))
 3421         continue
 3430       continue
c     3-----
          endif
c
c         call copyv(qu(1,i),a,6)
          call dcopy(6,qu(1,i),1,a,1)
c
c    -----  diagonalise quadrupole tensor of centre i
c
cnot          call diaaxs(a,trf,eig,ia,3,3,3)
c
          if (ndppr .ge. 5) then
            write (iwr,3511) i
 3511       format (' principal moments and vectors ',
     1              'of the quadrupole tensor of atom ',i3,':')
            write (iwr,3521) (eig(k) , k = 1, 3)
 3521       format (/,3e20.10,/)
            write (iwr,3531) ((trf(k,j), j = 1, 3), k = 1, 3)
 3531       format (3e20.10)
          endif
c
c    -----  generate 6 extra centra around the mulliken centre in
c           the direction of the eigenvectors of the diagonalised
c           quadrupole tensor
c
          dfact = dfacmx
          if (nscdis .eq. 0) then
            rr = -(qu(1,i) + qu(3,i) + qu(6,i))/three
            dfact = onept5/rr
            if (dfact .gt. dfacmx) dfact = dfacmx
            if (dfact .lt. dfacmn) dfact = dfacmn
          endif
c
          do 3450, l = 1, 3
            nexc0 = nexc0 + 2
            do 3441, k = 1, 3
              ce(k,nexc0-1) = ar(k) + dfact*trf(k,l)
              ce(k,nexc0) = ar(k) - dfact*trf(k,l)
 3441       continue
            if (nocnstr .le. 0) then
              qe(nexc0-1) = (pt5/dfact**2)*eig(l)
              qe(nexc0) = (pt5/dfact**2)*eig(l)
              qq(i) = qq(i) - eig(l)/(dfact**2)
            endif
 3450     continue
c   2-----
 3500   continue
c
        if (nocheck .eq. 0) then
c   2-----
c    -----  try to minimise the number of extra expansion centra
c           by looking if they are close to existing ones
c
          do 3600, l = 1, nexc0
c     3-----
            discard = .false.
            do 3510, i = 1, (nat + nexc0)
c       4-----
              if (l .ne. (i-nat)) then
                do 3501, k = 1, 3
                  if (i .le. nat) then
                    ar(k) = c(k,i)
                  else
                    ar(k) = ce(k,i-nat)
                  endif
 3501           continue
c
                call distab(ar,ce(1,l),ri,dist)
                if (dist .lt. discdis) then
c
c            -----  discard this extra point
c
                  discard = .true.
                  goto 3800
                endif
              endif
c       4-----
 3510       continue
c     3-----
 3600     continue
c
          if (.not. discard) then
c     3-----
c      -----  store the extra expansion centre and name it
c
            nexc = nexc + 1
            write(namnum,3611) nexc
 3611       format(i4)
            namec(nexc) = expnam//namnum
            do 3700, k = 1, 3
              ce(k,nexc) = ce(k,l)
 3700       continue
c     3-----
          endif
c     3-----
 3800     continue
c   2-----
        else
c   2-----
          nexc = nexc0
          do 3900, i = 1, nexc
            write(namnum,3611) i
            namec(i) = expnam//namnum
 3900     continue
c   2-----
        endif
c 1-----
      endif
c
      if (nocnstr .eq. 1) then
        call qpopan(itdist,nat,nat,c,c,q,p,qu,nexc,ce,qe,w,ihlp)
      else if (nocnstr .eq. -1) then
c
c  -----  read standard dp charges
c
        call daread (idafdrf,iodadrf,q,nat,114)
      endif
c
c-----  printed output of qp charges
c
      if ((.not. mcupdt) .or. (imcout .eq. 5)) then
        write(iwr,3911)
 3911   format(
     1//t20,36('-'),/t20,'charges preserving the quadrupole moment',
     2/t20,36('-'))
      endif
c
      do 4000, i = 1, nat + nexc
        if (i .le. nat) then
          qq(i) = qq(i) + q(i)
c         call copyv(c(1,i),cc(1,i),3)
          call dcopy(3,c(1,i),1,cc(1,i),1)
        else
          qq(i) = qe(i-nat)
c         call copyv(ce(1,i-nat),cc(1,i),3)
          call dcopy(3,ce(1,i-nat),1,cc(1,i),1)
          names(i) = namec(i-nat)//'      '
        endif
 4000 continue
      call printq(3,nat+nexc,qq,cc,names)
c
c-----  punch charges on internal points
c
      if(nprint.eq.-5) rewind ipnch
      write(ipnch,4011)
 4011 format('----  quadrupole conserving charges  ------'/)
      write(ipnch,*)'  name, charge, x, y, z'
      write(ipnch,*)' $qp-charges'
c
      do 4100, i = 1, nat
        write(ipnch,3111) anam(i),bnam(i),q(i),(c(k,i),k=1,3)
 4100 continue
c
      if (nogenxc .eq. 0) then
c 1-----
        if (ndppr .ge. 3) write (iwr,4021)
 4021   format (/,' coordinates of extra charge centra:')
        do 4200, i = 1, nexc
          write (ipnch,4211) namec(i), qe(i), (ce(k,i), k = 1, 3)
 4211     format (a10,6f10.6)
          if (ndppr .ge. 3) write (iwr,4221) (ce(k,i), k = 1, 3)
 4221     format (3f15.8)
 4200   continue
c 1-----
      endif
c
      write(ipnch,*) ' $end'
 3111 format(a8,a2,6f10.6)
c
c-----  write quadrupole preserving charges on -da31-, record -115-
c
      nchrp(6) = nat + nexc
      ichrp(6) = 104
      ncharp = nchrp(6)
      call dawrit(idafdrf,iodadrf,cc,3*ncharp,104,navdrf)
      call dawrit(idafdrf,iodadrf,qq,ncharp,115,navdrf)
c
      return
      end
      subroutine dipwrit(n,anam,bnam,p)
c------
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      dimension p(3,n)
c
      character*8 anam
      character*10 bnam
c
      dimension anam(n), bnam(n)
c
INCLUDE(comdrf/iofil)
c
c-----  begin
c
      write (iwr,1001)
c
 1001 format (/,' ----  mulliken dipoles: x, y, z ----')
c
      do 100, i = 1, n
c 1-----
        write(iwr,1011) anam(i)//bnam(i), (p(k,i), k = 1, 3)
 1011   format(a18,3(f10.5))
c 1-----
  100 continue
c
      return
      end
      subroutine quawrit(n,anam,bnam,qu)
c------
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      dimension qu(6,n)
c
      character*8 anam
      character*10 bnam
c
      dimension anam(n), bnam(n)
c
INCLUDE(comdrf/iofil)
c
c-----  begin
c
      write (iwr,1001)
c
 1001 format (/,
     2 ' ----  mulliken quadrupoles: xx, xy, yy, xz, yz, zz ----')
c
      do 100, i = 1, n
c 1-----
        write(iwr,1011) anam(i)//bnam(i), (qu(k,i), k = 1, 6)
 1011   format(a18,6(f10.5))
c 1-----
  100 continue
c
      return
      end
      subroutine qpopan(itdist,ndip,npnts,cp,cq,q,p,qu,
     1                  nexc,ce,qe,w,isign)
c------
c      --------  p.th. van duijnen, ibm-kingston 1985 -----
c
c     ndip = number of dipole moments
c     npnts= number of expansion points
c     cp   = coordinates of dipoles
c     cq   = coordinates of expansion centers
c     q    = charges(input&output)
c     p    = dipoles
c     w    = work space
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(comdrf/sizesrf)
c
      logical itdist
c
      dimension cp(3,ndip), p(3,ndip), w(*)
      dimension q(ndip)
      dimension qu(6,ndip)
      dimension cq(3,npnts)
      dimension isign(npnts)
      dimension ce(3,nexc)
      dimension qe(nexc)
c
INCLUDE(comdrf/iofil)
c
INCLUDE(comdrf/qpanl)
c
INCLUDE(comdrf/cenmas)
c
      dimension ri(3),ar(3),br(3),cr(3),dr(3),xav(3)
      dimension b(10,10), qav(3,3)
      dimension ia(3)
      dimension qmul(10), algrn(10)
c
      dimension pprob(3), qprob(6)
c
c      dimension qh(npnts+nexc)
c      dimension qh2(ndip,npnts+nexc)
      dimension qh(3000),qh2(3000,3000)
c
      dimension auxx(10)
      dimension indx(10)
c
      character *8 errmsg(3)
c
      data ia /0,1,3/
      data zero, pt5, one, two /0.d00,0.5d00,1.d00,2.0d00/
      data thresh, smallw /1.0d-05,1.0d-10/
      data errmsg /'program', 'stop in','-qpopan-'/
c
      weight(x)= exp(-x**2)
c
c-----  begin
c
      if (npnts+nexc.gt.3000) call caserr
     + ('qpopan: npnts+ nexc>3000, increase dimension of qh+qh2 >3000')
      if (ndip.gt.3000) call caserr
     + ('qpopan: ndip>3000 increase dimensions of qh >3000')
      qfact = sqrt(pt5)
      dfact = pt5
      nprob = 10
c
      call clear (qh,npnts+nexc)
      call clear (qh2,ndip*(npnts+nexc))
      call clear (qe,nexc)
c
c-----  loop over the muliken charges, dipoles and quadrupoles
c
      do 9000, i = 1, ndip
c 1-----
c  -----  initialise for iterative procedure
c
        itcount = 0
        erdold = zero
        erqold = zero
c
c  -----  position vector of mulliken centre in ar
c
        ar(1) = cp(1,i)
        ar(2) = cp(2,i)
        ar(3) = cp(3,i)
c
c  -----  bl is used for scaling the weight function
c
        bl = 10000000.
        do 8900, l = 1, npnts + nexc
          if (l .le. npnts) then
            call distab(ar,cq(1,l),br,bll)
          else
            call distab(ar,ce(1,l-npnts),br,bll)
          endif
          if ((bll .lt. bl) .and. (bll .gt. thresh)) bl = bll
 8900   continue
c
c
c  -----  loop over expansion points for definition of
c         lagrange coupling matrix b
c
        nsign = 0
        sum = zero
        call clear(xav,3)
        call clear(qav,9)
        call clear(b,100)
c
        do 8000, l = 1, npnts + nexc
c   2-----
c    -----  position vector of qp-charge point in ri
c
          do 7900, k = 1, 3
            if (l .le. npnts) then
              ri(k) = cq(k,l)
            else
              ri(k) = ce(k,l-npnts)
            endif
 7900     continue
c
c    -----  distance to mulliken centre into cr
c
          call distab(ri,ar,cr,al)
c
c    -----  weighting function
c
          wl = weight(al/bl)
c
          if (wl .gt. smallw) then
c     3-----
            nsign = nsign + 1
            isign(nsign) = l
            w(nsign) = wl
            sum = sum + wl
            call accum (ri,xav,wl,3)
            call accum2 (ri,qav,wl,3)
c     3-----
          endif
c   2-----
 8000   continue
c
        do 8100, k = 1, 3
          xav(k) = xav(k)/sum
          do 8050, j = 1, 3
            qav(k,j) = qav(k,j)/sum
 8050     continue
 8100   continue
c
        do 8200, ll = 1, nsign
c   2-----
          l = isign(ll)
          if (l .le. npnts) then
            call distab(xav,cq(1,l),ri,dist)
c           call copyv(cq(1,l),dr,3)
            call dcopy(3,cq(1,l),1,dr,1)
          else
            call distab(xav,ce(1,l-npnts),ri,dist)
c           call copyv(ce(1,l-npnts),dr,3)
            call dcopy(3,ce(1,l-npnts),1,dr,1)
          endif
          wl = w(ll)
c
c    -----  update matrix b
c
          b(1,1) = b(1,1) + wl
c
          do 7000, im = 1, 3
c     3-----
            b(1,im+1) = b(1,im+1) + wl*ri(im)
            b(im+1,1) = b(im+1,1) + dfact*wl*ri(im)
            do 6900, jm = 1, im
c       4-----
              ij = ia(im) + jm
c
              b(1,ij+4) = b(1,ij+4) + wl*
     2                  (dr(im)*dr(jm)-qav(im,jm))
              b(ij+4,1) = b(ij+4,1) + qfact*wl*
     2                  (dr(jm)*dr(im)-qav(jm,im))
c
              b(im+1,jm+1) = b(im+1,jm+1) + dfact*wl*ri(im)*ri(jm)
              b(jm+1,im+1) = b(jm+1,im+1) + dfact*wl*ri(jm)*ri(im)
c
              do 6800, km = 1, 3
c         5-----
                b(km+1,ij+4) = b(km+1,ij+4) + dfact*wl*
     2                       ri(km)*(dr(im)*dr(jm)-qav(im,jm))
                b(ij+4,km+1) = b(ij+4,km+1) + qfact*wl*
     2                       (dr(jm)*dr(im)-qav(jm,im))*ri(km)
                do 6700, lm = 1, km
                  kl = ia(km) + lm
                  b(ij+4,kl+4) = b(ij+4,kl+4) + dfact*wl*
     2 ((dr(jm)*dr(im)-qav(jm,im))*(dr(km)*dr(lm)-qav(km,lm)))
                  b(kl+4,ij+4) = b(kl+4,ij+4) + dfact*wl*
     2 ((dr(im)*dr(jm)-qav(im,jm))*(dr(lm)*dr(km)-qav(lm,km)))
 6700           continue
c         5-----
 6800         continue
c       4-----
 6900       continue
c     3-----
 7000     continue
c   2-----
 8200   continue
c
c  -----  collected mulliken moments
c
        qmul(1) = zero
        do 8450, im = 1, 3
          qmul(im+1) = p(im,i)
          do 8350, jm = 1, im
            ij = ia(im) + jm
            qmul(ij+4) = qu(ij,i)
 8350     continue
 8450   continue
c
c    -----  lu-decompose matrix b and solve coupling equations
c           to get the lagrange multiplyers
c
        if (ndppr .ge. 5) then
          write (iwr,*) ' coupling matrix:'
          write (iwr,8011) ((b(k,j), k = 1, 10), j = 1, 10)
 8011     format (10f8.3)
        endif
c
        idgt = 8
        ier = 0
        call ludatf2(b,nprob,nprob,idgt,d,d2,indx,auxx,wa,ier)
        if (ier .eq. 129) then
          write (6,8401)
 8401     format (/, ' the coupling matrix for the standard',
     1   ' quadrupole preserving analysis is singular:',/,
     2   ' try an alternative procedure')
          call hnderr(3,errmsg)
        endif
c
 8888   continue
c
        itcount = itcount + 1
c
        if (ndppr .ge. 5) then
          write (iwr,8311) itcount, (qmul(im), im = 1, 10)
 8311     format (/,' moments to be reproduced in the ',i3,
     1    '-th iteration: ',/,10f8.3)
        endif
c
        call luelmf(b,qmul,indx,nprob,nprob,algrn)
c
c  -----  update the quadrupole preserving charges
c
        do 8500, l = 1, nsign
c   2-----
          qmult = zero
          lcent = isign(l)
          wl = w(l)
c
          do 8400, k = 1, 3
            if (lcent .le. npnts) then
              ri(k) = cq(k,lcent)
            else
              ri(k) = ce(k,lcent-npnts)
            endif
 8400     continue
c
c    -----  position vector of qp-charge point in ri
c
          qmult = qmult + algrn(1)
c
          do 8440, im = 1, 3
c     3-----
            qmult = qmult + algrn(im+1)*(ri(im)-xav(im))
            do 8435, jm = 1, im
              ij = ia(im) + jm
              qmult = qmult + algrn(ij+4)*
     2              (ri(im)*ri(jm)-qav(im,jm))
 8435       continue
c     3-----
 8440     continue
c
          qh(lcent) = qh(lcent) + wl*qmult
          qh2(i,lcent) = qh2(i,lcent) + wl*qmult
c   2-----
 8500   continue
c
        if (itdist) then
c   2-----
c    -----  calculate overall dipole and quadrupole and compare
c           with input dipole and quadrupole
c           then try to correct for errors
c
          call clear (pprob,3)
          call clear (qprob,6)
          do 8700, ll = 1, nsign
            l = isign(ll)
c
            do 8650, k = 1, 3
              if (l .le. npnts) then
                ri(k) = cq(k,l)
              else
                ri(k) = ce(k,l-npnts)
              endif
 8650       continue
c
            do 8600, k = 1, 3
              pprob(k) = pprob(k) + qh2(i,l)*ri(k)
              do 8550, j = 1, k
                kj = ia(k) + j
                qprob(kj) = qprob(kj)
     2                    + qh2(i,l)*(ri(k)-cenms(k))*(ri(j)-cenms(j))
 8550         continue
 8600       continue
 8700     continue
c
          erdmx = zero
          erqmx = zero
          do 8800, k = 1, 3
            qmul(k+1) = p(k,i) - pprob(k)
            erdmx = max(abs(qmul(k+1)),erdmx)
            do 8750, j = 1, k
              kj = ia(k) + j
              qmul(kj+4) = qu(kj,i) - qprob(kj)
              erqmx = max(abs(qmul(kj+4)),erqmx)
 8750       continue
 8800     continue
c
c    -----  check convergence
c
          if (((erdmx .gt. erdold) .and. (erqmx .gt. erqold))
     1        .and. (itcount .gt. 5)) then
            write (iwr,8801) itcount, i
 8801       format (/,' iterative procedure for quadrupole preserving',
     2      ' charges ',/,
     3      ' diverges after ',i3, ' iterations ',/,
     4      ' for centre ',i3,':',/,
     5      ' try alternative procedure with other charge centra')
            goto 9000
          endif
c
c    -----  redistribute difference dipole and quadrupole
c
          if (((erdmx .gt. threshd) .or. (erqmx .gt. threshq))
     1           .and. (itcount .lt. maxitqp)) then
            erdold = erdmx
            erqold = erqmx
            goto 8888
          else if (itcount .ge. maxitqp) then
            write (iwr,8821) i, itcount
 8821       format (/, ' no convergence of dipole or quadrupole',
     2      ' for centre ',i3,' after ',i3,' iterations')
          endif
c   2-----
        endif
c 1-----  next mulliken centre
 9000 continue
c
      do 9200, l = 1, npnts + nexc
c
c  -----  add mulliken charge
c
        if (l .le. npnts) then
          q(l) = q(l) + qh(l)
        else
          qe(l-npnts) = qe(l-npnts) + qh(l)
        endif
 9200 continue
c
      return
      end
_ENDIF
c      subroutine copyv(a,b,n)
cc------
cc      copies vector a of length n into b
cc------
c      implicit REAL  (a-h,o-z),integer  (i-n)
cINCLUDE(../m4/common/sizes)
cINCLUDE(comdrf/sizesrf)
c      dimension a(n), b(n)
c      do 100, i = 1, n
c        b(i) = a(i)
c  100 continue
c      return
c      end
      subroutine asgnrf(nfit,nexp,icch,iexpas,defnew,each,asscen,
     1           oradial,nshels,ovl,
     1           dipx,dipy,dipz,xexf,elpot,delpot,xexp,iexpc,
     2 iso)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/timez)
INCLUDE(../m4/common/symtry)
INCLUDE(../m4/common/prints)
INCLUDE(../m4/common/prnprn)
INCLUDE(../m4/common/restar)
INCLUDE(../m4/common/segm)
INCLUDE(../m4/common/restri)
INCLUDE(../m4/common/statis)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/dump3)
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/nshel)
caleko
      common/nottwi/obeen,obeen2,obeen3,obeen4
caleko
      common/junk/s(225),g(225),
     *pint,qint,rint,t,p0,q0,r0,pi,qi,ri,pj,qj,rj,ni,nj,
     *tol,ii,jj,lit,ljt,mini,minj,maxi,maxj,iandk
INCLUDE(../m4/common/root)
      common/blkin/dxyz(4),gg(225),ft(225),fx(225),dij(225),
     * pin(225),qin(225),rin(225),
     * ijx(225),ijy(225),ijz(225)
c mechanics
INCLUDE(../m4/common/modj)
INCLUDE(../m4/common/g80nb)
INCLUDE(../m4/common/runlab)
c ***** omit specified charges from attraction terms ***
INCLUDE(../m4/common/chgcc)
INCLUDE(../m4/common/xfield)
c ******
cdrf
c     drf extension
c     ====================================================================
c         note: in hondo, o,x,y and z are real*8
c NCLUDE(comdrf/opt)
caleko
c nexp was not defined here; let's see if this helps
c      common/drfpar2/nxtpts,npol,nexp,natint,nshint,namb,nspec,ngran
caleko
          common/hefcpar/edumm(5,1000),nedumm,iefc
          common/hfldpar/fldxyz(3),ifld
          character*4 keyfld, keyefc, iefc, ifld
c NCLUDE(comdrf/dafil)
         integer idafh,navh
         common/hdafile/idafh,navh,ioda(2,1000)
         common/c_of_m/pcm,qcm,rcm
INCLUDE(../m4/common/drfopt)
INCLUDE(comdrf/darw)
INCLUDE(comdrf/sizesrf)
INCLUDE(comdrf/scfopt)
INCLUDE(comdrf/drfamb)
cahv
c
c-----  dummy variables
c
      REAL xexp
      dimension xexp(3,*)
      dimension iexpc(nx)
      REAL ovl 
      dimension ovl(nx)
      dimension dipx(nx), dipy(nx), dipz(nx)
      REAL xexf
      dimension xexf(3,nfit)
      dimension delpot(nexp,225)
      dimension elpot(nfit,225)
      logical defnew, each, asscen
      logical onec
      logical norm,double
      logical block,blocks,blocki
      logical some,out
      logical repeat, onetwo
      dimension cm(3)
      logical oradial
cdrf  ===================  end drfexts ===============================
cahv      dimension q(*),
      dimension iso(nshels,*)
      dimension ix(35),iy(35),iz(35),jx(35),jy(35),jz(35)
      dimension m0(48)
c
      data tols, told1, told2, told3 /1.d-02, 1.d-04, 1.d-20, 1.d-03/
      data  m51/51/
c mechanics
      data keyfld, keyefc /' fld',' efc'/
      data dzero,pt5,done,two,three,five,seven /0.0d0,0.5d0,1.0d0,
     + 2.0d0,3.0d0,5.0d0,7.0d0/
      data rnine/9.0d0/
      data eleven /11.0d0/
      data pi212 /1.1283791670955d0/
      data sqrt3 /1.73205080756888d0/
      data sqrt5 /2.23606797749979d0/
      data sqrt7 /2.64575131106459d0/
      data rln10 /2.30258d0/
      data jx / 0, 1, 0, 0, 2, 0, 0, 1, 1, 0,
     +          3, 0, 0, 2, 2, 1, 0, 1, 0, 1,
     +          4, 0, 0, 3, 3, 1, 0, 1, 0, 2,
     +          2, 0, 2, 1, 1/
      data ix / 1, 6, 1, 1,11, 1, 1, 6, 6, 1,
     *         16, 1, 1,11,11, 6, 1, 6, 1, 6,
     *         21, 1, 1,16,16, 6, 1, 6, 1,11,
     *         11, 1,11, 6, 6/
      data jy / 0, 0, 1, 0, 0, 2, 0, 1, 0, 1,
     +          0, 3, 0, 1, 0, 2, 2, 0, 1, 1,
     +          0, 4, 0, 1, 0, 3, 3, 0, 1, 2,
     +          0, 2, 1, 2, 1/
      data iy / 1, 1, 6, 1, 1,11, 1, 6, 1, 6,
     +          1,16, 1, 6, 1,11,11, 1, 6, 6,
     +          1,21, 1, 6, 1,16,16, 1, 6,11,
     +          1,11, 6,11, 6/
      data jz / 0, 0, 0, 1, 0, 0, 2, 0, 1, 1,
     +          0, 0, 3, 0, 1, 0, 1, 2, 2, 1,
     +          0, 0, 4, 0, 1, 0, 1, 3, 3, 0,
     +          2, 2, 1, 1, 2/
      data iz / 1, 1, 1, 6, 1, 1,11, 1, 6, 6,
     +          1, 1,16, 1, 6, 1, 6,11,11, 6,
     +          1, 1,21, 1, 6, 1, 6,16,16, 1,
     +         11,11, 6, 6,11/
cahv
      noprt = 1
      out =noprt.eq.1.and.nprint.eq.3
      num2=(num*(num+1))/2
c
c-----  define expansion centra
c
      call drfcm(cm)
      if (out) call hatout(cm  ,3,1   ,2,'cm  ')
c
c-----  read overlap integrals from da10
c
      call daread(idafh,ioda,ovl, num2,12)
c
c-----  calculate dipole moments relative to -cm-
c
cmw put the centre-of-mass information into the common
c   and call the gamess dipint
c   note that dipint was adapted for cm().
c   a common c_of_m is used to pass cm()
      pcm=cm(1)
      qcm=cm(2)
      rcm=cm(3)
cmw      call dipint(dipx,dipy,dipz,cm,num)
c     call dipint(dipx,dipy,dipz)
cahv  call dipxyz(dipx,dipy,dipz,num)
      call dipxyz(dipx,dipy,dipz)
c
      if (abs(iexpas) .ne. 2) then
c
c----- calculate radial overlap of charge distributions -----
c           ( this is accomplished by setting -lit-
c           and -ljt- equal to -1- regardless of
c           -ktype(ii)- and -ktype(jj)-. we are interested
c           in the -s- component only )
c
        if(out) write(iwr,9999)
 9999 format(//' radial overlap of charge distributions '
     1 /,1x,31(1h-))
c
        onetwo = iexpas .eq. -3
c
c
_IF(parallel)
c***   **MPP**
      iflop = iipsci()
c***   **MPP**
_ENDIF
      l1 = num
      l2 = (num*(num+1))/2
      l3 = num*num
      l4 = natmod*3
      l5 = natmod
      outv = oprint(59)
      nav = lenwrd()
      if (nprint.eq.-5) outv = .false.
c
c     ----- set pointers for partitioning of core -----
c
      i10 = 0
      i20 = i10 + l2
      i30 = i20 + l2
cdrf  i301 space for hamilonian in fldint
      i301 = i30 + l2
cdrf  last = i30 + l2
      last = i301 + l2
cIF(parallel)
      if (lpseud.le.1) then
         i40 = i30 + l2
         last = i40 + l2 + l1
      else
         i40 = i30 + l2
         i50 = i40 + l2
         i60 = i50 + l3
         i70 = i60 + 225*num
         i80 = i70 + 225*20
         i90 = i80 + (nat*nt+nav-1)/nav
         i100 = i90 + nw196(4)
         last = i100 + nw196(5)
      end if
c
c crystal field correction
c
c
c ***** allocate memory for charge exclusion
c
      if (omtchg) then
         i110 = last
         last = i110 + nat * nat
      endif
      call izero(l2,iexpc,1)
c
      length = last - i10
 
cahv      i10 = igmem_alloc(length)
      i10 = 1
      i20 = i10 + l2
      i30 = i20 + l2
      if (lpseud.le.1) then
         i40 = i30 + l2
         last = i40 + l2 + l1
      else
         i40 = i30 + l2
         i50 = i40 + l2
         i60 = i50 + l3
         i70 = i60 + 225*num
         i80 = i70 + 225*20
         last = i80 + (nat*nt+nav-1)/nav
      end if
c
c crystal field correction
c
      if(ocryst)then
         ic10 = last
         last = ic10 + l2
      endif
c ...
c mechanics
c ...
      if (oaminc) then
         ia40 = last
         ia50 = ia40 + l4
         ia60 = ia50 + l5
         last = ia60 + l5
      end if
c ***** allocate memory for charge exclusion
c<<<<<< intega.m
c      if (omtchg) then
c       i110 = last
c       last = i110 + nat * nat
c      endif
c======
      if (omtchg) then
         i110 = last
         last = i110 + nat * nat
      endif
c
c     ----- calculate -s- matrix -----
c
c     - s- at x(i10)
c
         cpu = cpulft(1)
cahv
         ncall = 0
cahv
         if (ncall.eq.0) call cpuwal(begin,ebegin)
cahv         if (ncall.eq.0 .and. outv) write (iwr,6030) cpu
         tol = rln10*itol
         out = nprint.eq.3
         if (out) then
           do ii = 1,6
            oprn(30+ii) = .true.
           enddo
          else
           do ii = 1,6
            if(oprn(30+ii)) out = .true.
           enddo
         endif
         onorm = normf.ne.1 .or. normp.ne.1
         ndum = l2 + l2 + l2
_IF(parallel)
cpsh
ccc         ndum = ndum + l2
_ENDIF
c         call vclr(q(i10),1,ndum)
c
c     ----- ishell
c
cjmht psh said this was an event tracer for tcgmsg and so is redundant
cjmht_IF(parallel)
cjmht         call pg_evbgin('par.')
cjmht_ENDIF
         do 440 ii = 1 , nshell
            i = katom(ii)
	    iat = i
	    iatom = i
c
c     ----- eliminate ishell -----
c
            do 450 it = 1 , nt
               id = iso(ii,it)
               if (id.gt.ii) go to 440
               m0(it) = id
450         continue
            icent = i
            pi = c(1,i)
            qi = c(2,i)
            ri = c(3,i)
            i1 = kstart(ii)
            i2 = i1 + kng(ii) - 1
            lit = ktype(ii)
            mini = kmin(ii)
            maxi = kmax(ii)
            loci = kloc(ii) - mini
c
c     ----- jshell
c
            do 430 jj = 1 , ii
_IF(parallel)
c***   **MPP**
               if (oipsci()) go to 430
c***   **MPP**
_ENDIF
               j = katom(jj)
	       jat = j
	       onec = iat .eq. jat
               n2 = 0
               do 470 it = 1 , nt
                  jd = iso(jj,it)
                  if (jd.gt.ii) go to 430
                  id = m0(it)
                  if (id.lt.jd) then
                     nd = id
                     id = jd
                     jd = nd
                  end if
                  if (id.eq.ii .and. jd.gt.jj) go to 430
                  if (id.eq.ii.and.jd.eq.jj) then
                      n2 = n2 + 1
                  end if
470            continue
               q2 = dble(nt)/dble(n2)
               jcent = j
               pj = c(1,j)
               qj = c(2,j)
               rj = c(3,j)
               j1 = kstart(jj)
               j2 = j1 + kng(jj) - 1
               ljt = ktype(jj)
               minj = kmin(jj)
               maxj = kmax(jj)
               locj = kloc(jj) - minj
               nroots = (lit+ljt-2)/2 + 1
               rr = (pi-pj)**2 + (qi-qj)**2 + (ri-rj)**2
               oiandj = ii.eq.jj
c
c     ----- prepare indices for pairs of (i,j) functions
c
               ij = 0
               max = maxj
               do 30 i = mini , maxi
                  nnx = ix(i)
                  nny = iy(i)
                  nnz = iz(i)
                  if (oiandj) max = i
                  do 20 j = minj , max
                     ij = ij + 1
                     ijx(ij) = nnx + jx(j)
                     ijy(ij) = nny + jy(j)
                     ijz(ij) = nnz + jz(j)
                     if (j.le.1) then
                        ft(ij) = three
                     else if (j.le.4) then
                        ft(ij) = five
                     else if (j.le.10) then
                        ft(ij) = seven
                     else if (j.gt.20) then
                        ft(ij) = eleven
                     else
                        ft(ij) = rnine
                     end if
 20               continue
 30            continue
               do 40 i = 1 , ij
                  s(i) = dzero
 40            continue
c
c     ----- i primitive
c
               jgmax = j2
               do 400 ig = i1 , i2
                  ai = ex(ig)
                  arri = ai*rr
                  axi = ai*pi
                  ayi = ai*qi
                  azi = ai*ri
                  csi = cs(ig)
                  if (oradial) then
                    cpi = cs(ig)
                    cdi = cs(ig)
                    cfi = cs(ig)
                    cgi = cs(ig)
                  else
                    cpi = cp(ig)
                    cdi = cd(ig)
                    cfi = cf(ig)
                    cgi = cg(ig)
                  endif
c
c     ----- j primtive
c
                  if (oiandj) jgmax = ig
                  do 390 jg = j1 , jgmax
                     aj = ex(jg)
                     aa = ai + aj
                     aa1 = done/aa
                     dum = aj*arri*aa1
                     if (dum.le.tol) then
                        fac = dexp(-dum)
                        csj = cs(jg)
                        if (oradial) then
                          cpj = cs(jg)
                          cdj = cs(jg)
                          cfj = cs(jg)
                          cgj = cs(jg)
                        else
                          cpj = cp(jg)
                          cdj = cd(jg)
                          cfj = cf(jg)
                          cgj = cg(jg)
                        endif
                        ax = (axi+aj*pj)*aa1
                        ay = (ayi+aj*qj)*aa1
                        az = (azi+aj*rj)*aa1
                        odoub = oiandj .and. ig.ne.jg
c
c     ----- density factor
c
                        max = maxj
                        nn = 0
                        do 220 i = mini , maxi
                           go to (50,60,120,120,
     +                            70,120,120,80,120,120,
     +                            90,120,120,100,120,120,120,120,120,
     +                            110,
     +                            112,120,120,114,120,120,120,120,120,
     +                            116,120,120,118,120,120), i
 50                        dum1 = csi*fac
                           go to 120
 60                        dum1 = cpi*fac
                           go to 120
 70                        dum1 = cdi*fac
                           go to 120
 80                        if (onorm) dum1 = dum1*sqrt3
                           go to 120
 90                        dum1 = cfi*fac
                           go to 120
 100                       if (onorm) dum1 = dum1*sqrt5
                           go to 120
 110                       if (onorm) dum1 = dum1*sqrt3
                           go to 120
 112                       dum1 = cgi*fac
                           go to 120
 114                       if (onorm) dum1 = dum1*sqrt7
                           go to 120
 116                       if (onorm) dum1 = dum1*sqrt5/sqrt3
                           go to 120
 118                       if (onorm) dum1 = dum1*sqrt3
 120                       if (oiandj) max = i
                           do 210 j = minj , max
                              go to (130,140,200,200,
     +                               150,200,200,160,200,200,
     +                               170,200,200,180,200,200,
     +                               200,200,200,190,
     +                               192,200,200,194,200,200,200,200,
     +                               200,196,200,200,198,200,200),j
 130                          dum2 = dum1*csj
                              if (odoub) then
                                 if (i.gt.1) then
                                    dum2 = dum2 + csi*cpj*fac
                                 else
                                    dum2 = dum2 + dum2
                                 end if
                              end if
                              go to 200
 140                          dum2 = dum1*cpj
                              if (odoub) dum2 = dum2 + dum2
                              go to 200
 150                          dum2 = dum1*cdj
                              if (odoub) dum2 = dum2 + dum2
                              go to 200
 160                          if (onorm) dum2 = dum2*sqrt3
                              go to 200
 170                          dum2 = dum1*cfj
                              if (odoub) dum2 = dum2 + dum2
                              go to 200
 180                          if (onorm) dum2 = dum2*sqrt5
                              go to 200
 190                          if (onorm) dum2 = dum2*sqrt3
                              go to 200
 192                          dum2 = dum1*cgj
                              if (odoub) dum2 = dum2 + dum2
                              go to 200
 194                          if (onorm) dum2 = dum2*sqrt7
                              go to 200
 196                          if (onorm) dum2 = dum2*sqrt5/sqrt3
                              go to 200
 198                          if (onorm) dum2 = dum2*sqrt3
 200                          nn = nn + 1
                              dij(nn) = dum2
 210                       continue
 220                    continue
c
c     ----- overlap and kinetic energy
c
                        t = dsqrt(aa1)
                        t1 = -two*aj*aj*t
                        t2 = -pt5*t
                        p0 = ax
                        q0 = ay
                        r0 = az
                        in = -5
                        do 240 i = 1 , lit
                           in = in + 5
                           if (oradial) then
                             ni = 1
                           else
                             ni = i
                           endif
                           do 230 j = 1 , ljt
                              jn = in + j
                              if (oradial) then
                                nj = 1
                              else
                                nj = j
                              endif
                              call stvint
                              pin(jn) = pint*t
                              qin(jn) = qint*t
                              rin(jn) = rint*t
 230                       continue
 240                    continue
                        do 250 i = 1 , ij
                         nnx = ijx(i)
                         nny = ijy(i)
                         nnz = ijz(i)
                         pyz = qin(nny)*rin(nnz)
                         dum = pyz*pin(nnx)
                         s(i) = s(i) + dij(i)*dum
 250                    continue
c
                     end if
c ...
c ...
 390              continue
 400           continue
c
c
c     ----- set up overlap matrix
c
               max = maxj
               nn = 0
               do 420 i = mini , maxi
                  li = loci + i
                  in = (li*(li-1))/2
                  if (oiandj) max = i
                  do 410 j = minj , max
                     lj = locj + j
                     jn = lj + in
                     nn = nn + 1
                     if (onec .and. oradial) then
                       iexp=iatom
                       goto 7660
                     endif
                     if (iexpas .eq. -1) then
                       if (onec) then
                         iexp = iatom
                       else
                         iexp = icch
                       endif
                       goto 7660
                     endif
c	     write(iwr,*) nn, jn, s(nn), ovl(jn)
                     if(abs(s(nn)) .le. tols .or. onetwo) then
c
c      -----  (overlap is small), centre is placed at middle of
c             originating atoms
c
                       ctrx = pt5*(c(1,iat)+c(1,jat)) - cm(1)
                       ctry = pt5*(c(2,iat)+c(2,jat)) - cm(2)
                       ctrz = pt5*(c(3,iat)+c(3,jat)) - cm(3)
c
                     else
c
c      -----  centre is located at dipole/overlap
c
                       dum=done/s(nn)
                       sign=done
                       dovl= abs(ovl(jn))
                       if(dovl.gt.dzero) sign=dovl/ovl(jn)
                       ctrx=dipx(jn)*dum*sign
                       ctry=dipy(jn)*dum*sign
                       ctrz=dipz(jn)*dum*sign
c
                     endif
c
c	     write (iwr,*) jn, ctrx, ctry, ctrz
                     if (each) then
c
c      -----  assign to each overlap distribution its own centre
c
c      -----  first check if overlap distribution coincides with
c             an already defined centre
c
                       do 7800, iex = 1, nexp
              dist2 = (xexp(1,iex)-ctrx)**2  
     2               +(xexp(2,iex)-ctry)**2
     1               +(xexp(3,iex)-ctrz)**2
                         if (dist2 .le. told3) then
                           iexp = iex
                           goto 7810
                         endif
 7800                  continue
c
c      -----  add new expansion centre
c
                       nexp = nexp + 1
                       xexp(1,nexp) = ctrx
                       xexp(2,nexp) = ctry
                       xexp(3,nexp) = ctrz
                       iexp = nexp
c
 7810                  continue
c
                     else
c
c      -----  find closest expansion center
c
                       nclos = 0
            dist=sqrt((ctrx-xexp(1,1))**2+
     1       (ctry-xexp(2,1))**2+
     2       (ctrz-xexp(3,1))**2)
                       rmin=dist
                       iexp=1
c
                       do 7630 npnt=2,nexp
              dist=sqrt((ctrx-xexp(1,npnt))**2+
     1       (ctry-xexp(2,npnt))**2+
     2       (ctrz-xexp(3,npnt))**2)
                         diff = dist - rmin
                         if (abs(diff) .le. told1) 
     1             nclos = nclos + 1
                         if(diff .gt. told1)
     1             goto 7630
                         rlast=rmin
                         rmin=dist
                         iexp=npnt
                         if (rmin-rlast .lt. -told1)
     1               nclos = 0
 7630                  continue
                       repeat = nclos .ne. 0
                       if (repeat) then
c           if (repeat .and. .not. onec) then
c
c        -----  two or more expansion centra are about equally
c               distant from the centre of the overlap distribution
c               create a new one if defnew = .true.
c
                         if (defnew) then
                           nexp = nexp + 1
                           xexp(1,nexp) = ctrx
                           xexp(2,nexp) = ctry
                           xexp(3,nexp) = ctrz
                           iexp = nexp
                         else if (iexpas .eq. 0) then
c
c          -----  assign ambiguous distribution to centre of charge
c
                           iexp = icch
                         endif
                       endif
c
c      -----  one-centre overlap distributions are assigned to the
c             origin of the basis functions
c
                     endif
c
                     if (nambpt(katom(ii)) .ne. 0) then
                       iexp = katom(ii)
                     endif
                     if (nambpt(katom(jj)) .ne. 0) then
                       iexp = katom(jj)
                     endif
c
 7660                iexpc(jn)=iexp
                     if (out) then
               write(6,9966) li,lj,dum,ctrx,ctry,ctrz,iexp
 9966          format(2i4,4e15.6,i4)
                     endif
c
 410              continue
 420           continue
 430        continue
 440     continue
c
       else
         write(iwr,*) 'ASSIGN: option not implemented'
         call caserr('ASSIGN: option not implemented')
       endif
c
c-----  transform -xexp- to global origin
c
      do 9100 i=1,nexp
        do 9100 l=1,3
          xexp(l,i)=xexp(l,i)+cm(l)
 9100 continue
_IF(parallel)
      call pg_igop(145,iexpc,l2,'+')
_ENDIF
cahv
      return
      end
