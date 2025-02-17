c 
c  $Author: hvd $
c  $Date: 2009-11-04 16:57:24 +0100 (Wed, 04 Nov 2009) $
c  $Locker:  $
c  $Revision: 6090 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mainci.m,v $
c  $State: Exp $
c  
c ******************************************************
c ******************************************************
c             =   blockcas   =
c ******************************************************
c ******************************************************
      block data mcscf
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/mlngth/nana(6)
      common/stak  /btri,mmmtri(4)
      common/stak2/ ctri,nnntri(4)
      common/bufc/cccc(510),icccc(4)
      common/testop/oto(20)
INCLUDE(common/avstat)
INCLUDE(common/simul)
INCLUDE(common/dm)
INCLUDE(common/ciconv)
INCLUDE(common/finish)
INCLUDE(common/ctrl)
      common/degen/ifdeg,idegen(100),ophase
INCLUDE(common/caspar)
      common/cone/m,na,nb,mf,nm1a,nm1b,mta1,mtb1,n82,iperm(8,8),ims(8)
      common/exc   /km,kkk,ql(5),idom(5),iocca(5,15),ioccb(5,15),irestu
     * , ifstr
      common/qpar/
     1ma,n2e,ntype,ncore,nact,nprim,nsec,nprimp,naa,nab,nst,n1e,isym,
     2mults,macro,maxc,itypci,itydrt,iduqpar
      common/cipar/clevc,accci,timeci,nitsci,nfudge,ncfl,ncfu,nprin
      common/blbpar/accblb,clev,timblb,nitblb,nprinb
      common/dims /ippd(12)
      common/popnos/ppo(300)
      common/add/ippa(27)
INCLUDE(common/qice)
      common/actlen/lena(108),ilifp(maxorb),lena2(24)
      common/potn/ppp(511)
      common/tab3/itab(4)
      common /drtlnk/ idrtln(6),labdrt(maxorb)
      common /loops / rloop(5),loops (15)
      common /form  / form  (8)
      common /valen / valen (2)
      common /casscg/ icas(4),icas2(maxorb)
      common /junkg / junkg (18)
      common/junke/maxt,ires,ipass,
     1nteff,mpass1,mpass2,lentri,
     2nbuck,mloww,mhi,ntri,jacc,ijunke(8)
      data oto/20*.false./
      data ipople/0/
      data itypci/5/
      data odoubl/.true./
      data nwt/1/
      data ifsimu,isimul,iam/0,n20cas*0,n20cas*0/
      data noci/n20cas*0/
      data iaugm/0/
      data fudgit,ojust,fmax/10*1.0d-5,.true.,.15d0/
      data osuped,swnr,swsimu,nhesnr/.true.,0.05d0,0.0d0,1/
      data ophase/.false./
      data macro/1/
cjvl  total # must be n20cas (=100)
      data isort/4*0,2,3*1,2,3*1,2,3*1,2,3*1,
     +           2,3*1,2,3*1,2,3*1,2,3*1,2,3*1,
     +           2,3*1,2,3*1,2,3*1,2,3*1,2,3*1,
     +           2,3*1,2,3*1,2,3*1,2,3*1,2,3*1,
     +           2,3*1,2,3*1,2,3*1,2,3*1,2,3*1/
      data nrever/0/
      data mode/0/
      data ifdeg,idegen/101*0/
      data ssz/1.3d0/
      data iperm/1,2,3,4,5,6,7,8,
     1           2,1,4,3,6,5,8,7,
     2           3,4,1,2,7,8,5,6,
     3           4,3,2,1,8,7,6,5,
     4           5,6,7,8,1,2,3,4,
     5           6,5,8,7,2,1,4,3,
     6           7,8,5,6,3,4,1,2,
     7           8,7,6,5,4,3,2,1/
      data idom(1),km,iocca,ioccb,irestu/1,1,151*0/
      data maxc/20/
      data icanon/3/
      data oconv/.false./
      data cccnv/1.0d-4/
      data timblb,nitblb,accblb,clev,nprinb/20.d0,40,
     *  1.0d-05,2.0d0,1000/
      data timeci,nitsci,accci,nfudge,ncfl,ncfu,nprin,clevc/
     *  30.d0,20,1.d-4,30,0,0,32000,0.0d0/
      end
c ******************************************************
c ******************************************************
c             =   blockci   =
c ******************************************************
c ******************************************************
      block data  mrdci
      implicit REAL  (a-h,p-z),integer   (i-n),logical     (o)
_IF(cray,ksr,i8)
      integer  mms,ms,nd32,n32m,mmms
_ELSEIF(convex,i8drct)
      integer *8  mms,ms,nd32,n32m,mmms
_ELSEIF(hp700,hpux11)
_ELSE
      REAL mms,ms,nd32,n32m,mmms
_ENDIF
_IFN(cray,convex,ksr,t3d,ibm)
      integer*4 mms_i,ms_i,mmms_i,nd32_i,n32m_i
_ENDIF
INCLUDE(common/sizes)
INCLUDE(common/cdcryi)
_IF(hp700,hpux11)
      common /cdcryz/ mms_i(2),ms_i(2),nd32_i(2),n32m_i(2),
     *  mmms_i(2)
_ELSE
      common /cdcryz/ mms,ms,nd32,n32m,mmms
_ENDIF
c
c    following common block definitions are to allow
c    gamess blocks to replace those in direct-ci
c    as follows
c    locol->junk; lhsrhs->three; symbol->scra; loco->lsort
c
c    to minimize core in scf gamess revert to definitions
c    in member blockall of this pds
c
      common/lsort/jlhs(mxcan1),jrhs(mxcan1),jr(mxcan1),
     *xj(mxcan1),
     *yj(mxcan1),nt9(16),jl9(16)
_IF(cray,ksr,i8)
      common /scra/ real2(3400),ireal2(6,3400)
_ELSE
      common /scra/ real2(3680),ireal2(3680,5)
_ENDIF
      common /three/ int3(4500)
c     common /junk / real4(4000),int4(9224)
INCLUDE(common/natorb)
      common/symchk/crtsym(2),nrep,osymd,osadap
      common/pager/ipage(20)
INCLUDE(common/outctl)
INCLUDE(common/hold)
INCLUDE(common/trial)
      common/erg/ptnuc(nd200+22),ipotnc(5)
INCLUDE(common/timanb)
INCLUDE(common/cic)
      common/dopey/nshif(127)
      common/xynumb/xnumb(6)
_IF(i8drct)
      integer *8 con12
_ENDIF
      common/expanc/con12(10),npopbb(2240)
      common/spew/rmodel(6)
INCLUDE(common/helpr)
      common/symcon/nornor(27)
INCLUDE(common/corctl)
      common /ccntl/ nnref(15)
      common/stoctl/iiiiii(32)
      common/moco/imoco(64),rmoco(64)
      common/cntrl/nval(14)
INCLUDE(common/diactl)
INCLUDE(common/symci)
INCLUDE(common/auxh)
      common /table/ nirrrr(68)
      common/disktl/nxblk(204)
INCLUDE(common/presrt)
       common/mapp/mapei(nd200*2+1)
INCLUDE(common/ccepa)
INCLUDE(common/comrjb)
c
      common/count/ iwrit,irea,iblkw,iblkr,iou2,lenou2,inn2,lenin2
      common/intbu2/ iblff(6),gggg(511)
      common/intbuf /mintb(4),gintb(511)
      common/couple /coupl(511),icoupl
      common/entryp /rorf(maxorb+1),irorbf
INCLUDE(common/mcff)
      common /mcopt / var,varc,thzr,done,dtwo
      common /mccore/ intrel,lword,ltop,lmax,lmin,mreal
INCLUDE(common/syminf)
INCLUDE(common/multic)
INCLUDE(common/jobopt)
      common/rotat/akkkk(60),nswap
      common/linkmc/lnkmc(12)
      common/mcaddr/iaddr(7)
      character*3 codes
      common /drtcoc/ codes(9)
      integer dela,delb,delele,virtul,occupd,valocc,rescor,resvir
     >       ,frozen,valvir,opensh,multi,speshl,multrf,valenc
     >       ,fzc,fzv,cor,vir,doc,uoc,alp,bet,spe
      common /drtcod/ ncodes,dela(9),delb(9),delele(9)
     1,               ntypes,virtul,occupd,valocc,rescor,resvir,frozen
     2,               valvir,opensh,multi,speshl,multrf,valenc
     3,   fzc, fzv, cor, vir, doc, uoc, alp, bet, spe
      integer orbfrm,symorb,optio,spec,sspesh
      common /drtinf/ na,nb,ns,nespec,maxb,levfrm,levval,levopn,levmul
     1,               levocc,spec,sspesh
     2, nbf,nsym,norbs,nrowsp,nrws4p,nrows,nrows4
     3,               nlevs,nrefs,nrowoc,nrow4o,nwks,nwksoc,nlevoc
     4,               orbfrm,symorb,numij,ngroup,numint,nmax,nspc
     5,optio(8)
c *** mrd/ci common blocks
      common/aplus/ra1(900),ra2(751),ra3(255),ira1(300),
     *   ira2(6,256),ira3(2040),ira4(12,8),ira5(2,9),ira6(3,4)
      common/linkmr/linkm(514)
      common/jany/jerk(10),jbnk(10),jbun(10)
      common/aaaa/icom(21)
      common/stak3/ dtri,llltri(4)
      common/bufd/dddd(510),idddd(4)
_IFN(parallel)
_IFN1(iv)      common/scrtch/cisd(185000)
_ENDIF
_IFN(cray,convex,ksr,t3d,ibm,hp700,hpux11)
      dimension mms_i(2),ms_i(2),mmms_i(2),nd32_i(2),n32m_i(2)
      equivalence (mms,mms_i),(ms,ms_i),
     * (mmms,mmms_i),(nd32,nd32_i),(n32m,n32m_i)
_ENDIF
c
      data icom /1,2,1,3,3,1,4,6,4,1,5,10,10,5,1,6,15,20,15,6,1/
      data jerk/0,30,118,158,248,274,321,0,0,0/
      data jbnk/4,17,7,15,3,5,7,0,0,0/
      data jbun/ 3,3,2,2,1,1,1,0,0,0/
c
      data n24,magic,n32,n64,n8,n16,n48/24,4,32,64,8,16,48/
c     /cic/
      data anumt/'one','two','three','four',
     *           'five','six','seven','eight'/
      data bnumt/'1','2','3','4',
     *           '5','6','7','8'/
_IF(ibm)
      data mms   /zffffff          /
      data ms    /zffff            /
      data mmms  /zff              /
      data nd32  /zaaaa000000000000/
      data n32m  /zaaaaaaaaaaaaaaaa/
_ELSEIF(cray,t3d)
      data mms  /77777777b/
      data ms   /177777b/
      data mmms /377b/
      data nd32 /1252520000000000000000b/
      data n32m /1252525252525252525252b/
_ELSEIF(convex,ksr)
      data mms  /'ffffff'x/
      data ms   /'ffff'x/
      data mmms /'ff'x/
      data nd32 /'aaaa000000000000'x/
      data n32m /'aaaaaaaaaaaaaaaa'x/
_ELSEIF(apollo)
      data mms_i/0,16#ffffff/,ms_i/0,16#ffff/
      data mmms_i/0,16#ff/
      data nd32_i/16#aaaa0000,16#00000000/
      data n32m_i/16#aaaaaaaa,16#aaaaaaaa/
_ELSEIF(hp700,hpux11,titan)
      data mms_i/0,'ffffff'x/,ms_i/0,'ffff'x/
      data mmms_i/0,'ff'x/
      data nd32_i/'aaaa0000'x,'00000000'x/
      data n32m_i/'aaaaaaaa'x,'aaaaaaaa'x/
_ELSEIF(sgi)
      data mms_i/0,$00ffffff/,ms_i/0,$0000ffff/
      data mmms_i/    0,        $000000ff/
      data nd32_i/    $aaaa0000,$00000000/
      data n32m_i/    $aaaaaaaa,$aaaaaaaa/
_ELSEIF(_NOT(linux))
_IF(rs6000)
      data mms_i/0,z00ffffff/,ms_i/0,z0000ffff/
      data mmms_i/    0,        z000000ff/
      data nd32_i/    zaaaa0000,z00000000/
      data n32m_i/    zaaaaaaaa,zaaaaaaaa/
_ENDIF
_ELSEIF(alliant,ipsc)
      data mms/'ffffff'x/,ms/'ffff'x/
      data mmms/'ff'x/
      data nd32/'aaaa000000000000'x/
      data n32m/'aaaaaaaaaaaaaaaa'x/
_ELSEIF(dec,vax)
      data mms_i/'ffffff'x,0/,ms_i/'ffff'x,0/
      data mmms_i/'ff'x,0/
      data nd32_i/'00000000'x,'aaaa0000'x/
      data n32m_i/'aaaaaaaa'x,'aaaaaaaa'x/
_ELSEIF(linux)
_IF(littleendian)
      data mms_i/z'ffffff',0/,ms_i/z'ffff',0/
      data mmms_i/z'ff',0/
      data nd32_i/z'00000000',z'aaaa0000'/
      data n32m_i/z'aaaaaaaa',z'aaaaaaaa'/
_ELSE
      data mms_i/0,'00ffffff'x/,ms_i/0,'0000ffff'x/
      data mmms_i/0,'000000ff'x/
      data nd32_i/'aaaa0000'x,'00000000'x/
      data n32m_i/'aaaaaaaa'x,'aaaaaaaa'x/
_ENDIF
_ELSE
c
c Sun format data statement, add code for new machines
c
      data mms_i/0,z'00ffffff'/,ms_i/0,z'0000ffff'/
      data mmms_i/    0,        z'000000ff'/
      data nd32_i/    z'aaaa0000',z'00000000'/
      data n32m_i/    z'aaaaaaaa',z'aaaaaaaa'/
_ENDIF
      end
      block data saveci
c
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c...  block data to initialise variables that could be better
c...  handled by save statements in subroutines
c...  unfortunately some compilers have trouble with those
c...  (variables have been checked not to cause interfeence
c...   in any of the other routines mentioned below)
c...   this is for ci-part
c
c...  subroutines affected :
c     initex    (casb) : common/cassav/mfrm
c
      common/cassav/mfrm
c
      end
      subroutine ver_mainci(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mainci.m,v $
     +     "/
      data revision /"$Revision: 6090 $"/
      data date /"$Date: 2009-11-04 16:57:24 +0100 (Wed, 04 Nov 2009) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
