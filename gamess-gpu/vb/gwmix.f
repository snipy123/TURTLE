      subroutine gwmix(ir,ic,ig,nblock,ialfa,w1,supg,nelec,n1,val)
c     Combines cikjl, pikjl, wmix, gmix, gather, ddot and subvec
c      from matre3.
      implicit real*8  (a-h,o-z) , integer   (i-n)
c
c     8note* tractlt noo included in vbdens.m mkd1vb
      integer iprint,nbasis,ncol,nsa,ncurt,lenact,lenbas,nactiv
      integer num3,iblkq,ionsec,nbsort,isecdu,n2int,setintpos
      logical incsort,oprs
      integer nnsort,isort,ksort,maxsort
      real*8 scri
c
      common /tractlt/ scri,iprint,nbasis,ncol,nsa,ncurt,lenact,lenbas,
     &                 num3,iblkq,ionsec,nbsort,isecdu,n2int,nactiv,
     &                 incsort,nnsort,isort,ksort,maxsort,oprs
c
c...  incsort : indicates if incore sorting is on
c...  nnsort : # sortbuffers
c...  isort : sortbuffer done
c...  ksort : adres of sortbuffers in qq (igmem_alloc)
c...  maxsort : maximum sort buffer used
      dimension w1(n1)
      dimension ig(5,nblock)
      dimension ir(nelec),ic(nelec),supg(*)
!$acc routine (intpos)
c  supg(0:n2int)
c
      val=0.0d0
      val_1=0.0d0
      val_2=0.0d0
      it = 0
c     print *,'remco ig::',nblock,ialfa
c     do i=1,nblock
c       print *,(ig(k,i),k=1,5)
c     enddo

!$acc data copyin(ir,ic) present(supg)
!$acc& copyin(ig(5,nblock), w1(1:n1), nblock)
      do 51 m=1,nblock
         !msta = ig(3,m)
         !mend = ig(3,m) + ig(1,m) - 1
         do 41 k=ig(3,m)+1, ig(3,m)+ig(1,m)-1
!$acc parallel loop reduction(+:val_1) async
            do 31 l=ig(3,m), k-1
!$acc loop reduction(+:val_1)
              do 21 i=ig(3,m)+1, ig(3,m)+ig(1,m)-1
!$acc loop reduction(+:val_1)
                do 11 j=ig(3,m), i-1
                  !cikjl: calculate the loop vars
                  ii=i-ig(3,m)+1
                  jj=j-ig(3,m)+1
                  kk=k-ig(3,m)+1
                  ll=l-ig(3,m)+1
                  !jacobi ratio theorem to calculate 2nd-o-cofacs
                  scal=w1((kk-1)*ig(1,m)+ii+ig(5,m)-1)*
     &                 w1((ll-1)*ig(1,m)+jj+ig(5,m)-1)-
     &                 w1((ll-1)*ig(1,m)+ii+ig(5,m)-1)*
     &                 w1((kk-1)*ig(1,m)+jj+ig(5,m)-1)
                  !(subvec ipos with ipose) * 2nd-o-cofactor, add to total
                  ! matrix element val
                  val_1=val_1+scal*(supg(intpos(ir(i),ic(k),ir(j),
     1            ic(l)))-supg(intpos(ir(i),ic(l),ir(j),ic(k))))
11                continue
21             continue
31         continue
!$acc end parallel loop
41       continue
51    continue

      do 690 m=1,nblock-1
        do 590 l=ig(4,m), ig(4,m+1)-1
!$acc parallel loop reduction(+:val_2) async
          do 490 j=ig(3,m), ig(3,m+1)-1
!$acc loop reduction(+:val_2)
            do 390 n=m+1, nblock
!$acc loop reduction(+:val_2)
              do 290 k=ig(4,n), ig(4,n)+ig(2,n)-1
!$acc loop reduction(+:val_2)
                do 190 i=ig(3,n), ig(3,n)+ig(1,n)-1
                  ! wmix: get the first order cofactor from w1
                  jl=(l-ig(4,m))*(ig(3,m+1)-ig(3,m))+j-ig(3,m)+ig(5,m)
                  scalar=w1(jl)
                  ! get first order cofactor from w1
                  ik=(k-ig(4,n))*(ig(3,n)+ig(1,n)-ig(3,n))+i
     1                -ig(3,n)+ig(5,n)
                  ! calc 2nd order cofactor * integral calc
                  ! add to total
                  if (m >= ialfa+1) then
                    val_2=val_2 - w1(ik)*scalar *
     3                  supg(intpos(ir(i),ic(l),ir(j),ic(k)))
                  end if

                  if (m <= ialfa-1 .and. n <= ialfa) then
                    val_2=val_2 - w1(ik)*scalar *
     2                  supg(intpos(ir(i),ic(l),ir(j),ic(k)))
                  end if
                    val_2=val_2+w1(ik)*scalar*
     1                  supg(intpos(ir(i),ic(k),ir(j),ic(l)))
190               continue
290             continue
390           continue
490         continue
!$acc end parallel loop
590       continue
690     continue
!$acc end data
      print *, "first:", val_1
      print *, "second:", val_2
!$acc wait
      val = val_1 + val_2
      print *, "done", val
      stop
      return
      end
   
      subroutine delintdev(supg)
      implicit real*8  (a-h,o-z) , integer   (i-n)
c     8note* tractlt noo included in vbdens.m mkd1vb
      integer iprint,nbasis,ncol,nsa,ncurt,lenact,lenbas,nactiv
      integer num3,iblkq,ionsec,nbsort,isecdu,n2int,setintpos
      logical incsort,oprs
      integer nnsort,isort,ksort,maxsort
      real*8 scri
c
      common /tractlt/ scri,iprint,nbasis,ncol,nsa,ncurt,lenact,lenbas,
     &                 num3,iblkq,ionsec,nbsort,isecdu,n2int,nactiv,
     &                 incsort,nnsort,isort,ksort,maxsort,oprs
c
c...  incsort : indicates if incore sorting is on
c...  nnsort : # sortbuffers
c...  isort : sortbuffer done
c...  ksort : adres of sortbuffers in qq (igmem_alloc)
c...  maxsort : maximum sort buffer used
      dimension supg(0:n2int)
!$acc exit data delete (supg)
      return
      end
    
      subroutine putintdev(supg)
      implicit real*8  (a-h,o-z) , integer   (i-n)
c     8note* tractlt noo included in vbdens.m mkd1vb
      integer iprint,nbasis,ncol,nsa,ncurt,lenact,lenbas,nactiv
      integer num3,iblkq,ionsec,nbsort,isecdu,n2int,setintpos
      logical incsort,oprs
      integer nnsort,isort,ksort,maxsort
      real*8 scri
c
      common /tractlt/ scri,iprint,nbasis,ncol,nsa,ncurt,lenact,lenbas,
     &                 num3,iblkq,ionsec,nbsort,isecdu,n2int,nactiv,
     &                 incsort,nnsort,isort,ksort,maxsort,oprs
c
c...  incsort : indicates if incore sorting is on
c...  nnsort : # sortbuffers
c...  isort : sortbuffer done
c...  ksort : adres of sortbuffers in qq (igmem_alloc)
c...  maxsort : maximum sort buffer used
      dimension supg(0:n2int)
!$acc enter data copyin(supg)
      return
      end
       
      function intposx(i,j,k,l)
      implicit real*8 (a-h,o-z)
!$acc routine
      intposx=0
      return
      end


c     line 54
!       do 60 m=1,nblock-1
!         print *, "first loop structure"
!         do 50 l=ig(4,m),ig(4,m+1)-1
!             do 40 j=ig(3,m),ig(3,m+1)-1
!               ! wmix: get the first order cofactor from w1
!               jl=(l-ig(4,m))*(ig(3,m+1)-ig(3,m))+j-ig(3,m)+ig(5,m)
!               scalar=w1(jl)
!               do 30 n=m+1,nblock
!                 do 20 k=ig(4,n),ig(4,n)+ig(2,n)-1
!                   do 10 i=ig(3,n),ig(3,n)+ig(1,n)-1
!                     ! get first order cofactor from w1
!                     ik=(k-ig(4,n))*(ig(3,n)+ig(1,n)-ig(3,n))+i
!      1                  -ig(3,n)+ig(5,n)
!                     ! calc 2nd order cofactor * integral calc
!                     ! add to total
!                     val=val+w1(ik)*scalar*
!      1                  supg(intpos(ir(i),ic(k),ir(j),ic(l)))
! 10                continue
! 20              continue
! 30            continue
! 40          continue
! 50       continue
! 60    continue
! c
!       do 120 m=1,ialfa-1
!         print *, "second loop structure"
!         do 110 l=ig(4,m),ig(4,m+1)-1
!             do 100 j=ig(3,m),ig(3,m+1)-1
!               ! wmix: get the first order cofactor from w1
!               jl=(l-ig(4,m))*(ig(3,m+1)-ig(3,m))+j-ig(3,m)+ig(5,m)
!               scalar=w1(jl)
!               do 90 n=m+1,ialfa
!                 do 80 k=ig(4,n),ig(4,n)+ig(2,n)-1
!                   do 70 i=ig(3,n),ig(3,n)+ig(1,n)-1
!                       ! get first order cofactor from w1
!                       ik=(k-ig(4,n))*(ig(3,n)+ig(1,n)-ig(3,n))+i
!      2                    -ig(3,n)+ig(5,n)
!                       ! calc 2nd order cofactor * integral calc
!                       ! add to total
!                       val=val-w1(ik)*scalar*
!      2                    supg(intpos(ir(i),ic(l),ir(j),ic(k)))
! 70                   continue
! 80                continue
! 90             continue
! 100         continue
! 110      continue
! 120   continue
!       do 180 m=ialfa+1,nblock-1
!         print *, "third loop structure"
!          do 170 l=ig(4,m),ig(4,m+1)-1
!             do 160 j=ig(3,m),ig(3,m+1)-1
!               ! wmix: get the first order cofactor from w1
!               jl=(l-ig(4,m))*(ig(3,m+1)-ig(3,m))+j-ig(3,m)+ig(5,m)
!               scalar=w1(jl)
!                 do 150 n=m+1,nblock
!                   do 140 k=ig(4,n),ig(4,n)+ig(2,n)-1
!                      do 130 i=ig(3,n),ig(3,n)+ig(1,n)-1
!                         ! get first order cofactor from w1
!                         ik=(k-ig(4,n))*(ig(3,n)+ig(1,n)-ig(3,n))+i
!      3                     -ig(3,n)+ig(5,n)
!                         ! calc 2nd order cofactor * integral calc
!                         ! add to total
!                         val=val-w1(ik)*scalar*
!      3                      supg(intpos(ir(i),ic(l),ir(j),ic(k)))
! 130                  continue
! 140               continue
! 150            continue
! 160         continue
! 170      continue
! 180   continue