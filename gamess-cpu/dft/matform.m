
      subroutine mat_form_2c(gout,ii,kk,basi,bask,
     &     imc,matrix_out,ndim)
C ****************************************************************
c
C Form two centre repulsion integral matrix 
c
c imc - current i index
c
C ****************************************************************
      implicit none
C *****************************************************************
C *Declarations			
C *			
C *In variables				
      REAL gout(*)
      integer ii,kk,basi,bask
      integer ndim
      integer imc

C *Out variable
      REAL matrix_out(ndim,*)

INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_indez)
INCLUDE(common/dft_shlnos)
INCLUDE(common/dft_mbasis)

C *Local variables		
      integer ltyi,ltyk
      integer inn,knn,nn,imn,kmc
C *End declarations					      *
C ***************************************************************
      inn=0
      imn=imc
c
c nb - should be able to simplify calling code by 
c handling offsets internally - currently we just check
c
      if(imc +1.ne. kloc(basi,ii))then
         write(6,*)'imc CHECK fail',imc,kloc(basi,ii)
      endif

      do ltyi=mini,maxi
        inn=inn+1 
        imn=imn+1
        knn=0
        do ltyk=mink,maxk
          knn=knn+1
          kmc=(kloc(bask,kk)+knn)-1
          nn=ijgt(inn)+klgt(knn)
          matrix_out(imn,kmc)=gout(nn)
        enddo
      enddo
c     write(6,*) ' '
      return
      end
      subroutine mat_save_2c(gout,ii,kk,te2c_int,ite2c_int)
C ****************************************************************
c
C Form two centre repulsion integral matrix 
c
c imc - current i index
c
C ****************************************************************
      implicit none
C *****************************************************************
C *Declarations			
C *			
C *In variables				
      REAL gout(*)
      integer ii,kk
      integer imc

C *Out variable
      integer ite2c_int
      REAL te2c_int(*)

INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_indez)
INCLUDE(common/dft_shlnos)
INCLUDE(common/dft_mbasis)

C *Local variables		
      integer ltyi,ltyk
      integer inn,knn,nn,imn,kmc
C *End declarations					      *
C ***************************************************************
      inn=0
      imn=ite2c_int
c
c nb - should be able to simplify calling code by 
c handling offsets internally - currently we just check
c
c     if(imc +1.ne. kloc(basi,ii))then
c        write(6,*)'imc CHECK fail',imc,kloc(basi,ii)
c     endif

      do ltyi=mini,maxi
        inn=inn+1 
        knn=0
        do ltyk=mink,maxk
          imn=imn+1
          knn=knn+1
          nn=ijgt(inn)+klgt(knn)
          te2c_int(imn)=gout(nn)
        enddo
      enddo
      ite2c_int = imn
c     write(6,*) ' '
      return
      end
      subroutine mat_load_2c(ii,kk,basi,bask,
     &     imc,matrix_out,ndim,te2c_int,ite2c_int)
C ****************************************************************
c
C Form two centre repulsion integral matrix 
c
c imc - current i index
c
C ****************************************************************
      implicit none
C *****************************************************************
C *Declarations			
C *			
C *In variables				
      integer ii,kk,basi,bask
      integer ndim
      integer imc
      integer ite2c_int
      REAL te2c_int(*)

C *Out variable
      REAL matrix_out(ndim,*)

INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_indez)
INCLUDE(common/dft_shlnos)
INCLUDE(common/dft_mbasis)

C *Local variables		
      integer ltyi,ltyk
      integer inn,knn,nn,imn,kmc
C *End declarations					      *
C ***************************************************************
      inn=ite2c_int
      imn=imc
c
c nb - should be able to simplify calling code by 
c handling offsets internally - currently we just check
c
c     if(imc +1.ne. kloc(basi,ii))then
c        write(6,*)'imc CHECK fail',imc,kloc(basi,ii)
c     endif

      do ltyi=mini,maxi
        imn=imn+1
        knn=0
        do ltyk=mink,maxk
          knn=knn+1
          kmc=(kloc(bask,kk)+knn)-1
          inn=inn+1 
          matrix_out(imn,kmc)=te2c_int(inn)
        enddo
      enddo
      ite2c_int = inn
c     write(6,*) ' '
      return
      end

_IF(ga)
      subroutine mat_form_2c_ga(gout,ii,kk,basi,bask)
C ****************************************************************
c
C Form two centre repulsion integral matrix as a global array
c
C ****************************************************************
      implicit none
C *In variables				
      REAL gout(*)
      integer ii,kk,basi,bask
      integer handle
      integer ilo, ihi, jlo, jhi

INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_indez)
INCLUDE(common/dft_shlnos)
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_dunlap_ga)

      integer ipg_nodeid

C *Local variables		
      integer ltyi,ltyk
      integer inn,knn,nn,ndim

      REAL buff(225)
C *End declarations					      *
C ***************************************************************
      inn=0

      ndim = maxi-mini+1
      do ltyi=mini,maxi
        inn=inn+1 
        knn=0
        do ltyk=mink,maxk
          knn=knn+1
          nn=ijgt(inn)+klgt(knn)
          buff(inn+ndim*(knn-1))=gout(nn)
        enddo
      enddo

cccc      write(6,*)'store 2c:',ipg_nodeid(), ii,kk,inn,knn

      ilo =  kloc(basi,ii)
      ihi =  ilo + (maxi - mini)
      jlo =  kloc(bask,kk)
      jhi =  jlo + (maxk - mink)

ccccc      write(6,*)'limits',ilo,ihi,jlo,jhi
      call pg_put(g_2c,ilo,ihi,jlo,jhi,
     &              buff,ndim)

      if(ii .ne. kk)then
c
c complete square
c         
         inn=0
         ndim = maxk-mink+1
         do ltyi=mink,maxk
            inn=inn+1 
            knn=0
            do ltyk=mini,maxi
               knn=knn+1
               nn=klgt(inn)+ijgt(knn)
               buff(inn+ndim*(knn-1))=gout(nn)
            enddo
         enddo

         ilo =  kloc(bask,kk)
         ihi =  ilo + (maxk - mink)
         jlo =  kloc(basi,ii)
         jhi =  jlo + (maxi - mini)

cccc      write(6,*)'limits2',ilo,ihi,jlo,jhi
         call pg_put(g_2c,ilo,ihi,jlo,jhi,
     &        buff,ndim)
      endif

      return
      end
_ENDIF

      subroutine mat_form_3c(gout,mini,maxi,minj,maxj,mink,maxk,
     &                       ao_basfn,cd_basfn,imc,
     &                       eri_scr)
C *****************************************************************
C *Description:                                                   *
C *Form two centre repulsion integral matrix using array pointers *
C *****************************************************************
      implicit none
C *****************************************************************
C *Declarations                                                   *
C *                                                              *
C *In variables                                                  *
      REAL gout(*)
      integer mini,maxi,minj,maxj,mink,maxk
      integer ao_basfn,cd_basfn
INCLUDE(common/dft_indez)
C *Out variables                                                 *
      REAL eri_scr(225,*)
      integer imc
C *Local variables                                               *
      integer ltyi,ltyj,ltyk
      integer ijn,knn,nn,ann,imm
C *End declarations                                              *
C ****************************************************************
      ijn=0
      ann=0
      do ltyi=mini,maxi
        do ltyj=minj,maxj
          ijn=ijn+1
          knn=0
          ann=ann+1
          imm=imc
          do ltyk=mink,maxk
            knn=knn+1
            imm=imm+1
            nn=ijgt(ijn)+klgt(knn)
            eri_scr(ann,imm)=gout(nn)
          enddo
        enddo
      enddo
      return
      end
      subroutine mat_save_3c(gout,mini,maxi,minj,maxj,mink,maxk,
     &                       te3c_int,ite3c_int)
C *****************************************************************
C *Description:                                                   *
C *Form two centre repulsion integral matrix using array pointers *
C *****************************************************************
      implicit none
C *****************************************************************
C *Declarations                                                   *
C *                                                              *
C *In variables                                                  *
      REAL gout(*)
      integer mini,maxi,minj,maxj,mink,maxk
INCLUDE(common/dft_indez)
C *Out variables                                                 *
      integer ite3c_int
      REAL te3c_int(*)
C *Local variables                                               *
      integer ltyi,ltyj,ltyk
      integer ijn,knn,nn,ann,imm
C *End declarations                                              *
C ****************************************************************
      ijn=0
      ann=0
      imm=ite3c_int
      do ltyi=mini,maxi
        do ltyj=minj,maxj
          ijn=ijn+1
          knn=0
          do ltyk=mink,maxk
            knn=knn+1
            imm=imm+1
            nn=ijgt(ijn)+klgt(knn)
            te3c_int(imm)=gout(nn)
          enddo
        enddo
      enddo
      ite3c_int = imm
      return
      end
      subroutine dvec_fill(locij,adens,
     &                     ii,jj,mini,maxi,minj,maxj,
     &                     dvec_scr)
C ***************************************************************
      implicit none
C ***************************************************************
C *Declarations				      *
      REAL adens(*)
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/nshel)
      integer locij
      integer mini,maxi,minj,maxj,ii,jj
      integer ibas_num,jbas_num
      REAL dvec_scr(*)
      integer lbai,lbaj,ijbas_num,inum,jnum
      integer dpos,ipos,jpos,maxa,mina
C ***************************************************************
      dpos=0
      ibas_num=0
      jbas_num=0
      ipos=kloc(ii)
      jpos=kloc(jj)
      inum=(kmax(ii)-kmin(ii))
      jnum=(kmax(jj)-kmin(jj))
      do lbai=0,inum
        ibas_num=ipos+(lbai)
        do lbaj=0,jnum
          dpos=dpos+1
          jbas_num=jpos+(lbaj)
          maxa=max(ibas_num,jbas_num)
          mina=min(ibas_num,jbas_num)
          ijbas_num=(((maxa*maxa)-maxa)/2)+mina
          dvec_scr(dpos)=adens(ijbas_num)
c         write(6,*) 'Locations:',ipos,jpos,ibas_num,jbas_num
c         write(6,*) 'DVEC:',ipos,jpos,ijbas_num,dvec_scr(dpos)
        enddo
      enddo
      locij=locij+ibas_num
      return
      end 
      subroutine dvec_fill2(locij,adens,bdens,
     &                      ii,jj,mini,maxi,minj,maxj,
     &                      dvec_scr)
C ***************************************************************
      implicit none
C ***************************************************************
C *Declarations				      *
      REAL adens(*), bdens(*)
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/nshel)
      integer locij
      integer mini,maxi,minj,maxj,ii,jj
      integer ibas_num,jbas_num
      REAL dvec_scr(*)
      integer lbai,lbaj,ijbas_num,inum,jnum
      integer dpos,ipos,jpos,maxa,mina
C ***************************************************************
      dpos=0
      ibas_num=0
      jbas_num=0
      ipos=kloc(ii)
      jpos=kloc(jj)
      inum=(kmax(ii)-kmin(ii))
      jnum=(kmax(jj)-kmin(jj))
      do lbai=0,inum
        ibas_num=ipos+(lbai)
        do lbaj=0,jnum
          dpos=dpos+1
          jbas_num=jpos+(lbaj)
          maxa=max(ibas_num,jbas_num)
          mina=min(ibas_num,jbas_num)
          ijbas_num=(((maxa*maxa)-maxa)/2)+mina
          dvec_scr(dpos)=adens(ijbas_num)+bdens(ijbas_num)
c         write(6,*) 'Locations:',ipos,jpos,ibas_num,jbas_num
c         write(6,*) 'DVEC:',ipos,jpos,ijbas_num,dvec_scr(dpos)
        enddo
      enddo
      locij=locij+ibas_num
      return
      end 
      subroutine km_fill(locij,ii,jj,kma,dvec_scr)
C *************************************************************
      implicit none
C *************************************************************
C *Declarations                                               *
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/nshel)
      REAL dvec_scr(*)
      integer ii,jj,locij
      integer ibas_num,jbas_num
      REAL kma(*)
      integer lbai,lbaj,inum,jnum
      integer dpos,ipos,jpos,maxa,mina,ijbas_num
C *************************************************************
      dpos=0
      ibas_num=0
      jbas_num=0
      ipos=kloc(ii)
      jpos=kloc(jj)
      inum=kmax(ii)-kmin(ii)
      jnum=kmax(jj)-kmin(jj)
      do lbai=0,inum
        ibas_num=ipos+lbai
        do lbaj=0,jnum
          dpos=dpos+1
          jbas_num=jpos+lbaj
          maxa=max(ibas_num,jbas_num)
          mina=min(ibas_num,jbas_num)
          ijbas_num=(((maxa*maxa)-maxa)/2)+mina
          kma(ijbas_num)=dvec_scr(dpos)
        enddo
      enddo
      locij=dpos
      return
      end 
      subroutine ver_dft_matform(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/matform.m,v $
     +     "/
      data revision /
     +     "$Revision: 5774 $"
     +      /
      data date /
     +     "$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $"
     +     /
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
