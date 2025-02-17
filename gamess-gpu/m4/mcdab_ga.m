c
c  mcdab using partial back-transformed amplitudes
c
      subroutine mcdab_ga(abdens,ii,jj,kk,ll
     &,  pmp2, hfden, nocca, nvirta, ncoorb, gns)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/cigrad)
INCLUDE(common/incrd)
INCLUDE(common/dmisc)
      dimension abdens(*), pmp2(*), hfden(*), gns(*)
      data half,one,two/0.5d0,1.0d0,2.0d0/
      logical iieqjj, iieqkk, iieqll, jjeqkk, jjeqll, kkeqll 
c
      iieqjj = ii.eq.jj
      iieqkk = ii.eq.kk
      iieqll = ii.eq.ll
      jjeqkk = jj.eq.kk
      jjeqll = jj.eq.ll
      kkeqll = kk.eq.ll
      mini = kloc(ii)
      minj = kloc(jj)
      mink = kloc(kk)
      minl = kloc(ll)
      maxi = kloc(ii+1) - 1
      maxj = kloc(jj+1) - 1
      maxk = kloc(kk+1) - 1
      maxl = kloc(ll+1) - 1
      ishl = maxi - mini + 1
      jshl = maxj - minj + 1
      kshl = maxk - mink + 1
      lshl = maxl - minl + 1

      fac = one

      if ( iieqkk .and. jj.ne.ll )  fac = half
c
c  form 2pdm over primitives
c
      do i = mini , maxi
         do j = minj , maxj
            j11 = (j-1)*ncoorb
            imn = j11 + i
            do k = mink , maxk
               k11 = (k-1)*ncoorb
               iml = k11 + i
               inl = k11 + j
               do l = minl , maxl
                  l11 = (l-1)*ncoorb
                  ils = l11 + k
                  ims = l11 + i
                  ins = l11 + j

c  SCF term of 2pdm -           ij         kl
                  dscf = hfden(imn)*hfden(ils)*4.0d0
     +                      - hfden(iml)*hfden(ins)
     +                      - hfden(ims)*hfden(inl)

c  MP2 separable term  - 
                  dsep =  pmp2(imn)
     +                   *hfden(ils) + pmp2(ils)*hfden(imn)
     +                   - (pmp2(iml)*hfden(ins)+pmp2(ims)
     +                   *hfden(inl)+pmp2(inl)*hfden(ims)
     +                   +pmp2(ins)*hfden(iml))*0.25d0

c  MP2 non-separable term -
                  igns = (i-mini)*kshl*jshl*ncoorb + 
     &                   (j-minj)*ncoorb + 
     &                   (k-mink)*jshl*ncoorb + l
                  dnon = gns(igns)

c  total MP2 gradient density -
                  gamma = dscf + two*(dsep + dnon)
c  permutational symmetry weight - 
                  gamma = gamma*fac
c gdf:                  gamma = gamma*q4
                  nn = (i-mini)*inc5 + (j-minj)*inc4 + 
     &                 (k-mink)*inc3 + (l-minl) + inc2
                  abdens(nn) = abdens(nn) + gamma
               end do
            end do
         end do
      end do
c
c  symmetrize density matrix 
c
      if ( iieqjj .or. kkeqll ) then 
      do i = mini , maxi
        jjmx = maxj
        if ( iieqjj ) jjmx = i
        do j = minj , jjmx
          do k = mink , maxk
            llmx = maxl
            if ( kkeqll ) llmx = k
            do l = minl , llmx
              ni = (i-mini)*inc5 + (j-minj)*inc4 + 
     &             (k-mink)*inc3 + (l-minl) + inc2
              if ( iieqjj .and. i.ne.j ) then
                nj = (j-minj)*inc5 + (i-mini)*inc4 + 
     &               (k-mink)*inc3 + (l-minl) + inc2
                di = abdens(ni)
                dj = abdens(nj)
                abdens(ni) = di + dj
                abdens(nj) = abdens(ni) 
                if ( kkeqll .and. k.ne.l ) then
                  nk = (i-mini)*inc5 + (j-minj)*inc4 + 
     &                 (l-minl)*inc3 + (k-mink) + inc2
                  nl = (j-minj)*inc5 + (i-mini)*inc4 + 
     &                 (l-minl)*inc3 + (k-mink) + inc2
                  dk = abdens(nk)
                  dl = abdens(nl)
                  abdens(nk) = dk + dl  
                  abdens(nl) = abdens(nk) 
                  abdens(ni) = half*( abdens(ni) + 
     &               abdens(nj) + abdens(nk) + abdens(nl) )
                  abdens(nj) = abdens(ni)
                  abdens(nk) = abdens(ni)
                  abdens(nl) = abdens(ni)
                end if
              else if ( kkeqll .and. k.ne.l ) then
                nj = (i-mini)*inc5 + (j-minj)*inc4 + 
     &               (l-minl)*inc3 + (k-mink) + inc2
                di = abdens(ni)
                dj = abdens(nj)
                abdens(ni) = di + dj 
                abdens(nj) = abdens(ni) 
              end if
            end do
          end do
        end do
      end do
c
      else if ( ( iieqkk .and. jjeqll ) .or. 
     &          ( iieqll .and. jjeqkk ) ) then 
      do i = mini , maxi
        do j = minj , maxj
          do k = mink , maxk
            do l = minl , maxl
              ni = (i-mini)*inc5 + (j-minj)*inc4 + 
     &             (k-mink)*inc3 + (l-minl) + inc2
              if ( iieqkk .and. jjeqll ) then 
                nj = (k-mink)*inc5 + (l-minl)*inc4 + 
     &               (i-mini)*inc3 + (j-minj) + inc2
              else if ( iieqll .and. jjeqkk ) then 
                nj = (l-minl)*inc5 + (k-mink)*inc4 + 
     &               (j-minj)*inc3 + (i-mini) + inc2
              end if
              di = abdens(ni)
              dj = abdens(nj)
              abdens(ni) =  ( di + dj )*half 
              abdens(nj) = abdens(ni) 
            end do
          end do
        end do
      end do
        if ( ii.ne.kk ) call dscal(lendd,two,abdens,1)
      end if
      return
      end
      subroutine ver_mcdab_ga(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mcdab_ga.m,v $
     +     "/
      data revision /"$Revision: 5774 $"/
      data date /"$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
