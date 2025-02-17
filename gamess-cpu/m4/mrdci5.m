c 
c  $Author: jmht $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci5.m,v $
c  $State: Exp $
c  
c ******************************************************
c ******************************************************
c             =   Table-ci (table module) =
c ******************************************************
c ******************************************************
      subroutine tdata
      implicit REAL  (a-h,o-z), integer (i-n)
      integer ot
      common/craypk/ot(4000),ic,i2,i3
      common/bufd/gout(510),ne,nspace
      common/b/ndat(5),nsac(5),iaz(5),iez(5),idra(5),
     * idrc(5),jdrc(5),jan(7),jbn(7),jsp(7)
INCLUDE(common/iofile)
      common/scrtch/a(15876),e(5292),ae(7829),
     + isq(10),jerk(10),iloc(5),imat(504),jmat(1439),
     + khog(5),jbne(10),nrd(5),
     + nplu(5),imar(5),
     + nytl(5),imike(4),ijog(10),jjog(10),itim(10),jhog(67),ipar(45),
     + imox(90),ibil(3),icol(126),irow(126),ihog(48),iper(4)
INCLUDE(common/prints)
      common/blksi3/nsz,nsz51(6),nsz510
      dimension lout(512)
      character*10 charwall
      equivalence (lout(1),gout(1))
      write(iwr,7777)
      nmax=10
      ibb=4000
      kmjx=48
      isrp=126
      ept=1.0d-15
      eps=0.001d0
_IFN(parallel)
      call setbfc
_ELSE
c **** MPP
      call closbf3
      call setbfc(-1)
c **** MPP
_ENDIF
      irec=0
      mmax=ot(1)
      if(mmax.le.0.or.mmax.gt.nmax)go to 7781
      do 7779 i=1,mmax
      isq(i)=ot(i+1)
      if(isq(i).le.0.or.isq(i).gt.5)go to 7781
 7779 continue
      write (iwr,900) mmax,(isq(i),i=1,mmax)
      do 2 nmul=1,mmax
      jerk(nmul)=irec
      iswh=isq(nmul)
      is=0
      ispin=(nmul-1)/2
      fms=ispin
      if (nmul.eq.2*(nmul/2)) fms=fms+0.5d0
      ibl=0
      nod=nmul-3
      max=0
      do 100 iw=1,iswh
      nod=nod+2
      nrd(iw)=nod
      write (iwr,241) nmul,nod
      nmns=iw-1
      nplu(iw)=nod-nmns
      if (nmns.ne.0) go to 101
      ndat(1)=1
      nsac(1)=1
      khog(1)=0
      ae(1)=1.0d0
      ae(2)=1.0d0
      iaz(1)=-1
      iez(1)=1
      jf=2
      imar(1)=1
      ihg=1
      jhog(1)=1
      iloc(1)=0
      if (nod.eq.0) go to 100
      do 80 j=1,nod
      is=is+1
  80  jmat(is)=1
      go to 100
101   ndet=nod
      if (nmns.gt.1) go to 300
      do 301 j=1,nod
  301 imat(j)=j
      go to 125
  300 nmon=1
      nmot=nod
      do 126 j=2,nmns
      nmot=nmot-1
      ndet=ndet*nmot
126   nmon=nmon*j
      ndet=ndet/nmon
      if (ndet.gt.isrp) go to 954
      do 128 j=1,nmns
      iper(j)=j
128   imat(j)=j
      ib=nmns
134   jb=nmns
      jm=nod
129   km=iper(jb)
      if (km.ne.jm) go to 130
      jb=jb-1
      if (jb.eq.0) go to 131
      jm=jm-1
      go to 129
130   ip=iper(jb)+1
      iper(jb)=ip
      if (jb.eq.nmns) go to 132
      jb=jb+1
      do 133 j=jb,nmns
      ip=ip+1
133   iper(j)=ip
132   do 135 j=1,nmns
      ib=ib+1
135   imat(ib)=iper(j)
      go to 134
131   if (ib.ne.ndet*nmns) go to 955
125   nx=nod*ndet
      nd=is+1
      ne=is+nx
      do 531 j=nd,ne
531   jmat(j)=1
      jh=0
      iloc(iw)=is
      do 532 j=1,ndet
      do 533 k=1,nmns
      jh=jh+1
      ly=imat(jh)+is
533   jmat(ly)=-1
532   is=is+nod
      fnod=nod
      khog(iw)=ihg
      fnod=fnod*0.5d0-fms
      nin=ndet+1
      nnam=-ndet
      do 136 j=1,ndet
      nnam=nnam+nin
136   a(nnam)=fnod
      ib=0
      kb=0
      do 137 j=2,ndet
      ib=ib+nmns
      j1=j-1
      jb=-nmns
      kb=kb+ndet
      lb=kb
      ilk=-ndet+j
      do 137 k=1,j1
      ilk=ilk+ndet
      lb=lb+1
      if (nmns.eq.1) go to 139
      mx=0
      jb=jb+nmns
      jn=jb
      do 138 l=1,nmns
      jn=jn+1
      ip=imat(jn)
      in=ib
      do 140 ll=1,nmns
      in=in+1
      if (imat(in)-ip) 140,138,141
140   continue
141   if (mx.eq.1) go to 142
      mx=1
138   continue
139   a(lb)=1.0d0
      go to 137
142   a(lb)=0.0d0
137   a(ilk)=a(lb)
      call dmfgr(a,ndet,ndet,eps,irank,irow,icol)
      kmj=ndet-irank
      if (kmj.gt.kmjx) go to 950
      ifac=nod+1-nmns
      ifac=(ifac-nmns)*ndet/ifac
      if (ifac.ne.kmj) go to 951
      if(oprint(31))write (iwr,4320) ndet,kmj
      if(oprint(31))write (iwr,4320) (icol(j),j=1,ndet)
      js=irank*ndet
      in=irank
      do 143 i=1,kmj
      in=in+1
      sum=1.0d0
      do 144 j=1,irank
      ico=(icol(j)-1)*ndet+in
      js=js+1
      ab=a(js)
      sum=sum+ab*ab
  144 a(ico)=ab
      k=irank
      js=js+kmj
      do 145 j=1,kmj
      k=k+1
      ico=(icol(k)-1)*ndet+in
      if (i.eq.j) go to 1460
      a(ico)=0.0d0
      go to 145
1460  a(ico)=1.0d0
145   continue
      k=in-ndet
      sum=1.0d0/dsqrt(sum)
      do 146 j=1,ndet
      k=k+ndet
146   a(k)=a(k)*sum
      if (i.eq.1) go to 143
      i1=i-1
      kb=1-ndet
      do 147 j=1,i1
      kb=kb+ndet
147   a(kb)=0
      jn=in-ndet
      kn=irank-ndet
      do 148 j=1,ndet
      jn=jn+ndet
      cj=a(jn)
      kb=1-ndet
      kn=ndet+kn
      ln=kn
      do 148 k=1,i1
      ln=ln+1
      kb=kb+ndet
148   a(kb)=a(kb)+cj*a(ln)
      kb=1-ndet
      sum=0.0d0
      do 149 k=1,i1
      kb=kb+ndet
      cj=a(kb)
149   sum=sum+cj*cj
      sum=-1.0d0/dsqrt(1.0d0-sum)
      kb=1-ndet
      do 150 j=1,i1
      kb=kb+ndet
150   a(kb)=a(kb)*sum
      kb=kb+ndet
      a(kb)=-sum
      nb=i-kmj
      lb=-kmj
      do 151 j=1,ndet
      sum=0.0d0
      lb=lb+ndet
      jb=lb
      kb=1-ndet
      do 152 k=1,i
      kb=kb+ndet
      jb=jb+1
152   sum=sum+a(jb)*a(kb)
      nb=nb+ndet
151   a(nb)=sum
143   continue
      ir=irank
      do 250 i=1,kmj
      ir=ir+1
250   ihog(i)=icol(ir)
      ir=0
      nb=-kmj
      do 154 i=1,kmj
      nb=nb+1
      kb=nb
      do 154 j=1,ndet
      ir=ir+1
      kb=kb+ndet
154   e(ir)=a(kb)
      jb=kmj*ndet
      if(oprint(32))write (iwr,4322) (e(j),j=1,jb)
      imar(iw)=jb
      ndat(iw)=ndet
      nsac(iw)=kmj
      iaz(iw)=jf-ndet
      do 534 j=1,jb
      jf=jf+1
  534 ae(jf)=e(j)
      iez(iw)=jf
      do 535 j=1,kmj
      ihg=ihg+1
  535 jhog(ihg)=ihog(j)
      jb=-kmj
      do 157 i=1,kmj
      ix=ihog(i)
      ib=ix*ndet-kmj
      jb=jb+1
      kb=jb
      do 157 j=1,kmj
      ib=ib+1
      kb=kb+kmj
157   e(kb)=a(ib)
      ie=-kmj
      jp=-kmj
      il=-kmj
      do 158 i=1,kmj
      il=il+kmj
      jl=il
      jp=jp+1
      kp=jp
      ie=ie+1
      je=-kmj
      do 158 j=1,i
      jl=jl+1
      kp=kp+kmj
      sum=0.0d0
      je=je+1
      jk=je
      ik=ie
      do 159 k=1,kmj
      ik=ik+kmj
      jk=jk+kmj
159   sum=sum+e(ik)*e(jk)
      a(kp)=sum
158   a(jl)=sum
      call dgelg(e,a,kmj,kmj,ept,ier)
      if (ier.eq.0) go to 160
      write(iwr,161) ier
      go to 7781
160   jl=kmj*kmj
      do 536 j=1,jl
      jf=jf+1
 536  ae(jf)=e(j)
      if(oprint(32))write (iwr,4322)  (e(j),j=1,jl)
100   continue
      nq=(jf-1)/nsz510+2
      jbne(nmul)=nq
      irec=irec+nq
      jrec=irec
      do 537 j=1,iswh
      nod=nrd(j)
      kmj=nsac(j)
      if(j.lt.3) go to 538
      ibl=ibl+1
      jan(ibl)=irec
      nd=nod*(nod-1)*(nod-2)*(nod-3)/24
      nd=nd*(1+kmj+kmj)
      nd=(nd-1)/ibb+1
      jbn(ibl)=nd
      irec=irec+nd
538   if(j.eq.1) go to 539
      ibl=ibl+1
      nd=12
      if(nod.lt.3) go to 540
      ne=nod*(nod-1)*(nod-2)*(nod-2)/6
      nd=ne*(1+kmj+kmj)+nd
540   ne=nod*(nod-1)/2
      nd=ne*kmj+nd
      nf=(nod+nmul)*kmj+1
      nd=nf*ne+nd
      nd=(nd-1)/ibb+1
      jan(ibl)=irec
      jbn(ibl)=nd
      irec=irec+nd
539   idra(j)=irec
      nps=nplu(j)
      nms=j-1
      if(nps.lt.2) nps=0
      if(nms.lt.2) nms=0
      nps=kmj*(nms+nps)+3*nms*nps*kmj+kmj+12
      nd=(nps-1)/ibb+1
      idrc(j)=nd
      irec=irec+nd
      nd=kmj+12
      if(nod.lt.2) go to 541
      nps=nod*(nod-1)/2
      nps=nps*(nps+1)/2
      nps=nps*(3*kmj+1)
      nd=nd+nps
541   if(nod.eq.0) go to 542
      nps=nod*(nod+1)/2
      nd=nd+nps*(1+kmj)
      nd=nd+nps*(2*nod*kmj+1)
542   nd=(nd-1)/ibb+1
      jdrc(j)=nd
537   irec=irec+nd
c
      call stopbk3
      jjj=jerk(nmul)
_IF(cray,ksr)
      call fmove(ndat,lout,49)
_ELSE
      call icopy(49,ndat,1,lout,1)
_ENDIF
      call sttout3(jjj)
      call stopbk3
      jjj=jjj+nsz
      ne=0
      do 543 j=1,jf
      ne=ne+1
      gout(ne)=ae(j)
      if(ne.ne.nsz510)go to 543
      call sttout3(jjj)
      call stopbk3
      ne=0
      jjj =jjj +nsz
 543  continue
      if(ne.eq.0)go to 5555
      call sttout3(jjj)
      call stopbk3
 5555 if(oprint(31))
     *write (iwr,75) ndat,nsac,iaz,iez,idra,idrc,jdrc,jan,jbn
      jbl=0
      nmns=-1
      do 551 j=1,iswh
c
      ic=0
      i2=0
      i3=0
      call pack12
      if(oprint(31)) then
       write(6,*) 'pack12 - 551: ic,i2,i3'
       write(6,5544) ic,i2,i3
      endif
c
      ihg=khog(j)
      nqns=nmns
      nmns=nmns+1
      nod=nrd(j)
      ndet=ndat(j)
      kmj=nsac(j)
      ii=kmj+kmj+1
c     ja=iaz(j)
      kr=iloc(j)-nod
      jps=nplu(j)
      kmt=kmj*jps
      if(j.lt.3) go to 552
      jbl=jbl+1
      mm=0
      nodj=nod-4
      j8=j-2
      ndj=ndat(j8)
      jr=iloc(j8)-nodj
      do 553 k=1,4
553   imike(k)=k
      nix=0
      if(nodj.eq.0) go to 558
561   ipr=1
      ips=imike(1)
      do 554 k=1,nod
554   itim(k)=k
      do 555 k=1,nod
      k1=k+1
590   ico=itim(k)
      if(ico.ne.ips) go to 555
      nix=nix+nod-k
      do 559 l=k1,nod
559   itim(l-1)=itim(l)
      itim(nod)=ips
      if(ipr.eq.4) go to 558
      ipr=ipr+1
      ips=imike(ipr)
      go to 590
555   continue
558   mm=mm+1
      ico=1
      if(nix-2*(nix/2).gt.0) ico=-1
      ot(mm)=ico
      if(mm.lt.ibb) go to 560
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      jrec=jrec+nsz
      mm=0
560   jhg=ihg
      do 562 k=1,kmj
      mm=mm+1
      jhg=jhg+1
      khg=jhog(jhg)
      nd=khg*nod+kr
      nps=0
      ipr=1
      ico=imike(1)
      do 563 l=1,nod
      nd=nd+1
      if(l.eq.ico) go to 564
      nps=nps+1
      ijog(nps)=jmat(nd)
      go to 563
564   itim(ipr)=jmat(nd)
      if(ipr.eq.4) go to 563
      ipr=ipr+1
      ico=imike(ipr)
563   continue
      if(itim(1).gt.0) go to 565
      if(itim(2).gt.0) go to 566
      if(itim(3).gt.0) go to 567
569   ot(mm)=0
      if(mm.lt.ibb) go to 568
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
568   mm=mm+1
      if(mm.lt.ibb) go to 562
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
      go to 562
567   if(itim(4).lt.0) go to 569
      ico=1
      go to 570
566   if(itim(3).gt.0) go to 571
      if(itim(4).lt.0) go to 569
      ico=2
      go to 570
571   if(itim(4).gt.0) go to 569
      ico=3
      go to 570
565   if(itim(2).lt.0) go to 572
      if(itim(3).gt.0) go to 569
      if(itim(4).gt.0) go to 569
      ico=1
      go to 570
572   if(itim(3).gt.0) go to 573
      if(itim(4).lt.0) go to 569
      ico=3
      go to 570
573   if(itim(4).gt.0) go to 569
      ico=2
570   if(nodj.gt.0) go to 574
      ot(mm)=1
      if(mm.lt.ibb) go to 575
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
575   mm=mm+1
      ot(mm)=ico
      if(mm.lt.ibb) go to 562
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
      go to 562
574   nps=jr
      do 576 l=1,ndj
      nps=nps+nodj
      ipr=nps
      do 577 m=1,nodj
      ipr=ipr+1
      if (ijog(m).ne.jmat(ipr)) go to 576
577   continue
      go to 579
576   continue
      go to 7781
579   ot(mm)=l
      if(mm.lt.ibb) go to 580
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
580   mm=mm+1
      ot(mm)=ico
      if(mm.lt.ibb) go to 562
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
562   continue
      if(nodj.eq.0) go to 616
      nix=0
      ipr=2
      ico=imike(1)+1
170   if(ico.eq.imike(ipr)) go to 581
      imike(ipr-1)=ico
      if (ipr.eq.2) go to 561
      ibd=ipr-2
      do 866 k=1,ibd
 866  imike(k)=k
      go to 561
581   if(ipr.eq.4) go to 582
      ico=ico+1
      ipr=ipr+1
      go to 170
 582  if (ico.eq.nod) go to 616
      imike(4)=ico+1
      do 867 k=1,3
 867  imike(k)=k
      go to 561
616   if(mm.eq.0) go to 584
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      jrec=jrec+nsz
      go to 584
552   if(j.eq.1) go to 583
584   nodj=nod-2
      j8=j-1
      jr=iloc(j8)-nodj
      ndj=ndat(j8)
      jbl=jbl+1
      ic=13-ii
      mm=12
      nd=12
      if(nod.lt.3) go to 585
      ne=nod*(nod-1)*(nod-2)*(nod-2)/6
      nd=ne*ii+nd
585   i2=nd-kmj
      jj=nod+nmul
      ne=nod*(nod-1)/2
      i3=nd+(ne-jj)*kmj
      call pack12
      if(oprint(31)) then
       write(6,*) 'pack12 - 585: ic,i2,i3'
       write(6,5544) ic,i2,i3
      endif
      if(nod.lt.3) go to 586
      do 587 k=1,3
587   imike(k)=k
      nix=0
      if(nod.eq.3) go to 588
589   ipr=1
      ips=imike(1)
      do 162 k=1,nod
162   itim(k)=k
      do 592 k=1,nod
      k1=k+1
593   ico=itim(k)
      if(ico.ne.ips) go to 592
      nix=nix+nod-k
      do 163 l=k1,nod
163   itim(l-1)=itim(l)
      itim(nod)=ips
      if(ipr.eq.3) go to 588
      ipr=ipr+1
      ips=imike(ipr)
      go to 593
592   continue
588   ica=1
      if(nix-2*(nix/2).gt.0) ica=-1
      ipr=nodj
      do 594 k=1,nodj
      ipr=ipr-1
      jco=ica
      if(ipr-2*(ipr/2).gt.0) jco=-jco
      mm=mm+1
      ot(mm)=jco
      if(mm.lt.ibb) go to 595
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
595   jhg=ihg
      do 596 l=1,kmj
      mm=mm+1
      jhg=jhg+1
      khg=jhog(jhg)
      nd=khg*nod+kr
      nps=0
      ipl=1
      ico=imike(1)
      do 597 m=1,nod
      nd=nd+1
      if(m.eq.ico) go to 598
      nps=nps+1
      if(nps.ne.k) go to 599
      nps=nps+1
599   ijog(nps)=jmat(nd)
      go to 597
598   itim(ipl)=jmat(nd)
      if(ipl.eq.3) go to 597
      ipl=ipl+1
      ico=imike(ipl)
597   continue
      if(itim(1).gt.0) go to 600
      if(itim(2).gt.0) go to 601
      if(itim(3).gt.0) go to 602
603   ot(mm)=0
      if (mm.lt.ibb) go to 604
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
604   mm=mm+1
      if(mm.lt.ibb) go to 596
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
      go to 596
602   ico=-1
      ijog(k)=-1
      go to 605
601   if(itim(3).gt.0) go to 606
      ico=-2
      ijog(k)=-1
      go to 605
606   ico=3
      ijog(k)=1
      go to 605
600   if(itim(2).gt.0) go to 607
      if(itim(3).gt.0) goto 608
      ico=-3
      ijog(k)=-1
      go to 605
608   ico=2
      ijog(k)=1
      go to 605
607   if(itim(3).gt.0) go to 603
      ico=1
      ijog(k)=1
605   nps=jr
      do 609 m=1,ndj
      nps=nps+nodj
      ipl=nps
      do 610 n=1,nodj
      ipl=ipl+1
      if(ijog(n).ne.jmat(ipl)) go to 609
610   continue
      go to 611
609   continue
      go to 7781
611   ot(mm)=m
      if(mm.lt.ibb) go to 612
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
612   mm=mm+1
      ot(mm)=ico
      if(mm.lt.ibb) go to 596
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
596   continue
594   continue
      if(nod.eq.3) go to 586
      nix=0
      ipr=2
      ico=imike(1)+1
613   if(ico.eq.imike(ipr)) go to 614
      imike(ipr-1)=ico
      if (ipr.eq.3) imike(1)=1
      go to 589
614   if(ipr.eq.3) go to 615
      ico=ico+1
      ipr=ipr+1
      go to 613
615   if(ico.eq.nod) go to 586
      imike(3)=ico+1
      imike(1)=1
      imike(2)=2
      go to 589
586   imike(1)=1
      imike(2)=2
      max=0
      mix=0
      nix=0
      if(nod.eq.2) go to 627
621   ipr=1
      ips=imike(1)
      do 622 k=1,nod
622   itim(k)=k
      do 624 k=1,nod
      k1=k+1
625   ico=itim(k)
      if(ico.ne.ips) go to 624
      nix=nix+nod-k
      do 626 l=k1,nod
626   itim(l-1)=itim(l)
      itim(nod)=ips
      if(ipr.eq.2) go to 627
      ipr=2
      ips=imike(2)
      go to 625
624   continue
627   ica=1
      if(nix-2*(nix/2).gt.0) ica=-1
      max=max+1
      ipar(max)=ica
      mix=mix+2
      imox(mix)=imike(2)
      imox(mix-1)=imike(1)
      jhg=ihg
      do 628 k=1,kmj
      mm=mm+1
      jhg=jhg+1
      khg=jhog(jhg)
      nd=khg*nod+kr
      nps=0
      ipr=1
      ico=imike(1)
      do 629 l=1,nod
      nd=nd+1
      if(l.eq.ico) go to 166
      nps=nps+1
      ijog(nps)=jmat(nd)
      go to 629
166   itim(ipr)=jmat(nd)
      if(ipr.eq.2) go to 629
      ipr=2
      ico=imike(2)
629   continue
      if(itim(1).gt.0) go to 631
      if(itim(2).gt.0) go to 632
634   ot(mm)=0
      if(mm.lt.ibb) go to 628
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
      go to 628
632   jco=-1
      go to 633
631   if(itim(2).gt.0) go to 634
      jco=1
633   if(ica.eq.-1) jco=-jco
      if(ndj.ne.1) go to 646
      l=1
      go to 637
646   nps=jr
      do 635 l=1,ndj
      nps=nps+nodj
      ipr=nps
      do 636 m=1,nodj
      ipr=ipr+1
      if(ijog(m).ne.jmat(ipr)) go to 635
636   continue
      go to 637
635   continue
      go to 7781
637   if(jco.eq.-1) l=-l
      ot(mm)=l
      if(mm.lt.ibb) go to 628
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
628   continue
      if(nodj.eq.0) go to 630
      nix=0
      ico=imike(1)+1
      if(ico.eq.imike(2)) go to 165
      imike(1)=ico
      go to 621
165   if(ico.eq.nod) go to 630
      imike(2)=ico+1
      imike(1)=1
      go to 621
 630  mix=0
      do 638 k=1,max
      ica=ipar(k)
      mm=mm+1
      ot(mm)=ica
      if(mm.lt.ibb) go to 640
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
640   nn=mm
      mix=mix+2
      imike(1)=imox(mix-1)
      imike(2)=imox(mix)
      jhg=ihg
      do 680 l=1,kmj
      mm=nn+1
      iba=jrec
      jhg=jhg+1
      khg=jhog(jhg)
      nd=khg*nod+kr
      nps=0
      ipr=1
      ico=imike(1)
      do 641 m=1,nod
      nd=nd+1
      if(m.eq.ico) go to 642
      nps=nps+1
      ijog(nps) =jmat(nd)
      go to 641
642   itim(ipr)=jmat(nd)
      if(ipr.eq.2) go to 641
      ipr=2
      ico=imike(2)
641   continue
      if(itim(1).lt.0) go to 643
      if(itim(2).gt.0) go to 644
      ot(mm)=1
      if(ndj.ne.1)    go to 647
      m=1
      go to 648
647   nps=jr
      do 645 m=1,ndj
      nps=nps+nodj
      ipr=nps
      do 649 n=1,nodj
      ipr=ipr+1
      if(ijog(n).ne.jmat(ipr))go to 645
649   continue
      go to 648
645   continue
      go to 7781
648   if(mm.lt.ibb) go to 650
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
650   mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 651
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
651   if(nodj.eq.0) go to 639
      do 653 m=1,nodj
      if (ijog(m).lt.0) go to 653
      mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 653
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
653   continue
      if(j8.eq.1) go to 639
      do 654 m=1,nodj
      if(ijog(m).gt.0) go to 654
      mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 654
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
654   continue
      go to 639
643   if(itim(2).lt.0) go to 655
      ot(mm)=2
      if(mm.lt.ibb) go to 656
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
656   if(ndj.ne.1) go to 657
      m=1
      go to 658
657   nps=jr
      do 659 m=1,ndj
      nps=nps+nodj
      ipr=nps
      do 660 n=1,nodj
      ipr=ipr+1
      if(ijog(n).ne.jmat(ipr)) go to 659
660   continue
      go to 658
659   continue
      go to 7781
658   mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 661
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
661   if(nodj.eq.0) go to 639
      if(j8.eq.1) go to 663
      do 662 m=1,nodj
      if(ijog(m).gt.0) go to 662
      mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 662
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
662   continue
663   do 664 m=1,nodj
      if(ijog(m).lt.0) go to 664
      mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 664
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
664   continue
      go to 639
644   ot(mm)=3
      if(mm.lt.ibb) go to 665
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
665   do 666 m=1,nodj
      if(ijog(m).gt.0) go to 666
      do 667 n=1,nodj
667   jjog(n)=ijog(n)
      jjog(m)=1
      nps=jr
      do 668 n=1,ndj
      nps=nps+nodj
      ipr=nps
      do 669 if=1,nodj
      ipr=ipr+1
      if(jjog(if).ne.jmat(ipr)) go to 668
669   continue
      go to 672
668   continue
      go to 7781
672   mm=mm+1
      ot(mm)=n
      if(mm.lt.ibb) go to 671
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
671   mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 666
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
666   continue
      go to 639
655   ot(mm)=4
      if(mm.lt.ibb) go to 673
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
673   do 674 m=1,nodj
      if(ijog(m).lt.0) go to 674
      do 675 n=1,nodj
675   jjog(n)=ijog(n)
      jjog(m)=-1
      nps=jr
      do 676 n=1,ndj
      nps=nps+nodj
      ipr=nps
      do 677 if=1,nodj
      ipr=ipr+1
      if(jjog(if).ne.jmat(ipr)) go to 676
677   continue
      go to 678
676   continue
      go to 7781
678   mm=mm+1
      ot(mm)=n
      if(mm.lt.ibb) go to 679
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
679   mm=mm+1
      ot(mm)=m
      if(mm.lt.ibb) go to 674
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
674   continue
639   nn=nn+jj
      if(nn.lt.ibb) go to 680
      nn=nn-ibb
      if (jrec.gt.iba) go to 680
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      jrec=jrec+nsz
680   continue
638   mm=nn
      if(mm.eq.0) go to 681
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      jrec=jrec+nsz
      go to 681
 583  ot(13)=1
      if(jps.lt.2) go to 682
      i2=1
      mm=13
      call pack12
      if(oprint(31)) then
       write(6,*) 'pack12 - 583: ic,i2,i3'
       write(6,5544) ic,i2,i3
      endif
      do 683 k=1,jps
      mm=mm+1
683   ot(mm)=k
      mix=0
      ipr=1
      jpr=2
 798  mix=mix+2
      imox(mix-1)=ipr
      imox(mix)=jpr
      nix=ipr+jpr
      ica=1
      if (nix-2*(nix/2).eq.0) ica=-1
      max=max+1
      ipar(max)=ica
      ipr=ipr+1
      if (ipr.lt.jpr) go to 798
      if (jpr.eq.nod) go to 682
      jpr=jpr+1
      ipr=1
      go to 798
 681  ic=kmj
      i2=kmj+jps*nmns*3*kmj
      i3=i2+kmt
      mm=12
      call pack12
      if(oprint(31)) then
       write(6,*) 'pack12 - 681: ic,i2,i3'
       write(6,5544) ic,i2,i3
      endif
      ipr=kr
      icy=0
      jhg=ihg
      do 302 k=1,kmj
      mm=mm+1
      jhg=jhg+1
 302  ot(mm)=jhog(jhg)
      do 684 k=1,ndet
      ipr=ipr+nod
      ico=ipr
      do 685 l=1,nod
      ico=ico+1
      if(jmat(ico).gt.0) go to 685
      icy=icy+1
      imat(icy)=l
685   continue
684   continue
       icy=ihg
      do 857 if=1,kmj
      icy=icy+1
      ih=jhog(icy)
      il=(ih-1)*nmns
      jl=-nmns
      do 857 k=1,ndet
      jl=jl+nmns
      if (ih.eq.k) go to 857
      kl=il
      nix=0
      mix=0
      do 859 l=1,nmns
      kl=kl+1
      kzl=imat(kl)
      ll=jl
      do 860 kk=1,nmns
      ll=ll+1
      if(kzl-imat(ll)) 861,862,860
862   mix=mix+1
      ibil(mix)=kk
      go to 859
  860 continue
861   if (nix.eq.1) go to 857
      nix=1
      mal=kzl
859   continue
      if (j.gt.2) go to 791
      nal=imat(jl+1)
      go to 865
 791  do 864 l=1,nqns
      if(ibil(l).eq.l) go to 864
      nal=imat(jl+l)
      go to 865
864   continue
      nal=imat(jl+nmns)
865   mm=mm+1
      ot(mm)=k
      if (mm.lt.ibb) go to 792
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
 792  mm=mm+1
      if (mal.gt.nal) go to 793
      ot(mm)=nal
      if (mm.lt.ibb) go to 794
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
 794  mm=mm+1
      ot(mm)=mal
      if (mm.lt.ibb) go to 857
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
      go to 857
 793  ot(mm)=mal
      if (mm.lt.ibb) go to 795
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
 795  mm=mm+1
      ot(mm)=nal
      if (mm.lt.ibb) go to 857
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
857   continue
      if(jps.lt.2) go to 688
      jhg=ihg
      do 689 k=1,kmj
      jhg=jhg+1
      nd=jhog(jhg)*nod+kr
      do 690 l=1,nod
      nd=nd+1
      if(jmat(nd).lt.0) go to 690
      mm=mm+1
      ot(mm)=l
      if(mm.lt.ibb) go to 690
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
690   continue
689   continue
      if(j.eq.2) go to 688
      jhg=ihg
      do 691 k=1,kmj
      jhg=jhg+1
      nd=jhog(jhg)*nod+kr
      do 692 l=1,nod
      nd=nd+1
      if(jmat(nd).gt.0) go to 692
      mm=mm+1
      ot(mm)=l
      if(mm.lt.ibb) go to 692
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
692   continue
691   continue
688   if(mm.eq.0) go to 693
682   call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      jrec=jrec+nsz
693   mm=12
      jhg=ihg
      do 694 k=1,kmj
      jhg=jhg+1
      mm=mm+1
694   ot(mm)=jhog(jhg)
      if(nod.gt.1) go to 695
      if(nod.eq.0) go to 797
      i2=mm-kmj
      jj=nod+nod
      i3=mm+kmj+1-jj*kmj
      call pack12
      if(oprint(31)) then
       write(6,*) 'pack12 - 694: ic,i2,i3'
       write(6,5544) ic,i2,i3
      endif
      go to 735
797   call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      jrec=jrec+nsz
      go to 551
695   ii=ii+kmj
      ic=mm-ii+1
      nps=max*(max+1)/2
      i2=mm+nps*ii-kmj
      jj=nod+nod
      i3=i2+kmj+(nod+max)*(kmj+1)-jj*kmj
      call pack12
      if(oprint(31)) then
       write(6,*) 'pack12 - 695: ic,i2,i3'
       write(6,5544) ic,i2,i3
      endif
      mix=0
      do 698 k=1,max
      mix=mix+2
      imike(1)=imox(mix-1)
      imike(2)=imox(mix)
      ica=ipar(k)
      nix=0
      do 698 l=1,k
      nix=nix+2
      jjog(1)=imox(nix-1)
      jjog(2)=imox(nix)
      jca=ipar(l)
      if(ica.gt.0) go to 699
      jca=-jca
699   mm=mm+1
      ot(mm)=jca
      if(mm.lt.ibb) go to 700
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
700   jhg=ihg
      do 701 m=1,kmj
      mm=mm+1
      jhg=jhg+1
      khg=jhog(jhg)
      nd=khg*nod+kr
      nps=0
      ipr=1
      ico=imike(1)
      jpr=jjog(1)
      do 702 n=1,nod
      nd=nd+1
      if(n.eq.ico) go to 703
      nps=nps+1
705   if(nps.ne.jpr) go to 702
      nps=nps+1
      if(ipr.eq.2) go to 702
      ipr=2
      jpr=jjog(2)
      go to 705
702   ijog(nps)=jmat(nd)
703   ico=imike(2)
      itim(1)=jmat(nd)
      jca=n+1
      do 706 n=jca,nod
      nd=nd+1
      if(n.eq.ico) go to 707
      nps=nps+1
708   if(nps.ne.jpr) go to 706
      nps=nps+1
      if(ipr.eq.2) go to 706
      ipr=2
      jpr=jjog(2)
      go to 708
706   ijog(nps)=jmat(nd)
 707  itim(2)=jmat(nd)
      if (n.eq.nod) go to 710
      jca=n+1
      do 711 n=jca,nod
      nd=nd+1
      nps=nps+1
712   if(nps.ne.jpr) go to 711
      nps=nps+1
      if(ipr.eq.2) go to 711
      ipr=2
      jpr=jjog(2)
      go to 712
711   ijog(nps)=jmat(nd)
710   if(itim(1).lt.0) go to 713
      if(itim(2).lt.0) go to 714
      ot(mm)=1
      if(mm.lt.ibb) go to 715
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
715   ipr=jjog(1)
      ijog(ipr)=1
      ipr=jjog(2)
      ijog(ipr)=1
722   nps=kr
      do 716 n=1,ndet
      nps=nps+nod
      ipr=nps
      do 717 if=1,nod
      ipr=ipr+1
      if(ijog(if).ne.jmat(ipr)) go to 716
717   continue
      go to 718
716   continue
      go to 7781
718   mm=mm+1
      ot(mm)=n
      if(mm.lt.ibb) go to 719
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
719   mm=mm+1
      if(mm.lt.ibb) go to 701
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
      go to 701
713   if(itim(2).gt.0) go to 720
      ot(mm)=1
      if(mm.lt.ibb) go to 721
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
721   ipr=jjog(1)
      ijog(ipr)=-1
      ipr=jjog(2)
      ijog(ipr)=-1
      go to 722
714   ot(mm)=2
      if(mm.lt.ibb) go to 723
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
723   ipr=jjog(1)
      ijog(ipr)=-1
      jco=1
      jpr=jjog(2)
      ijog(jpr)=1
728   nps=kr
      do 724 n=1,ndet
      nps=nps+nod
      kpr=nps
      do 725 if=1,nod
      kpr=kpr+1
      if(ijog(if).ne.jmat(kpr)) go to 724
725   continue
      go to 726
724   continue
      go to 7781
726   mm=mm+1
      ot(mm)=n
      if(mm.lt.ibb) go to 727
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
727   if(jco.lt.0) go to 701
      ijog(ipr) =1
      ijog(jpr)=-1
      jco=-1
      go to 728
720   ot(mm)=2
      if(mm.lt.ibb) go to 729
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
729   ipr=jjog(1)
      ijog(ipr)=1
      jpr=jjog(2)
      ijog(jpr)=-1
      jco=1
730   nps=kr
      do 731 n=1,ndet
      nps=nps+nod
      kpr=nps
      do 732 if=1,nod
      kpr=kpr+1
      if(ijog(if).ne.jmat(kpr)) go to 731
732   continue
      go to 733
731   continue
      go to 7781
733   mm=mm+1
      ot(mm)=n
      if(mm.lt.ibb) go to 734
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
734   if(jco.lt.0) go to 701
      ijog(ipr)=-1
      ijog(jpr)=1
      jco=-1
      go to 730
701   continue
698   continue
735   do 736 k=1,nod
      ica=k
      do 736 l=1,k
      mm=mm+1
      ica=ica+1
      jca=-1
      if(ica-2*(ica/2).gt.0) jca=1
      ot(mm)=jca
      if(mm.lt.ibb) go to 737
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
737   if(j.eq.1) go to 746
      jhg=ihg
      do 738 m=1,kmj
      mm=mm+1
      jhg=jhg+1
      khg=jhog(jhg)
      nd=khg*nod+kr
      itim(l)=jmat(nd+k)
      nps=0
      do 740 n=1,nod
      nd=nd+1
      if(n.eq.k) go to 740
      nps=nps+1
      if(nps.ne.l) go to 741
      nps=nps+1
741   itim(nps)=jmat(nd)
740   continue
      nps=kr
      do 744 n=1,ndet
      nps=nps+nod
      ipr=nps
      do 745 if=1,nod
      ipr=ipr+1
      if(itim(if).ne.jmat(ipr)) go to 744
745   continue
      go to 747
744   continue
      go to 7781
747   ot(mm)=n
      if(mm.lt.ibb) go to 738
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  738 continue
      go to 736
  746 do 748 m=1,kmj
      mm=mm+1
      ot(mm)=1
      if (mm.lt.ibb) go to 748
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  748 continue
  736 continue
      do 749 k=1,nod
      ica=k
      do 749 l=1,k
      mm=mm+1
      ica=ica+1
      jca=1
      if (ica-2*(ica/2).gt.0) jca=-1
      ot(mm)=jca
      if (mm.lt.ibb) go to 750
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  750 if (j.eq.1) go to 752
      jhg=ihg
      do 751 m=1,kmj
      mm=mm+1
      jhg=jhg+1
      khg=jhog(jhg)
      nd=khg*nod+kr
      ipr=jmat(nd+k)
      itim(l)=ipr
      nps=0
      do 753 n=1,nod
      nd=nd+1
      if (n.eq.k) go to 753
      nps=nps+1
      if (nps.ne.l) go to 754
      nps=nps+1
  754 itim(nps)=jmat(nd)
  753 continue
      nps=kr
      do 755 n=1,ndet
      nps=nps+nod
      jpr=nps
      do 756 if=1,nod
      jpr=jpr+1
      if (itim(if).ne.jmat(jpr)) go to 755
  756 continue
      go to 757
  755 continue
      go to 7781
  757 jpr=1
      if (ipr.lt.0) jpr=2
      ot(mm)=jpr
      if (mm.lt.ibb) go to 758
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
 758  mm=mm+1
      ot(mm)=n
      if (mm.lt.ibb) go to 759
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  759 if (jpr.eq.2) go to 760
      nps=0
      do 761 n=1,nod
      if (n.eq.l) go to 761
      nps=nps+1
      if (itim(n).lt.0) go to 761
      mm=mm+1
      if (mm.lt.ibb) go to 762
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  762 mm=mm+1
      ot(mm)=nps
      if (mm.lt.ibb) go to 761
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  761 continue
      nps=0
      do 764 n=1,nod
      if (n.eq.l) go to 764
      nps=nps+1
      if (itim(n).gt.0) go to 764
      do 765 if=1,nod
  765 ijog(if)=itim(if)
      ijog(l)=-1
      ijog(n)=1
      jca=kr
      do 766 if=1,ndet
      jca=jca+nod
      mal=jca
      do 767 nal=1,nod
      mal=mal+1
      if (ijog(nal).ne.jmat(mal)) go to 766
  767 continue
      go to 768
  766 continue
      go to 7781
  768 mm=mm+1
      ot(mm)=if
      if (mm.lt.ibb) go to 769
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  769 mm=mm+1
      ot(mm)=nps
      if (mm.lt.ibb) go to 764
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  764 continue
      go to 751
  760 if (j.eq.2) go to 784
      nps=0
      do 775 n=1,nod
      if (n.eq.l) go to 775
      nps=nps+1
      if (itim(n).gt.0) go to 775
      mm=mm+1
      if (mm.lt.ibb) go to 776
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
776   mm=mm+1
      ot(mm)=nps
      if(mm.lt.ibb) go to 775
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
775   continue
784   nps=0
      do 777 n=1,nod
      if(n.eq.l) go to 777
      nps=nps+1
      if(itim(n).lt.0) go to 777
      do 778 if=1,nod
778   ijog(if)=itim(if)
      ijog(l)=1
      ijog(n)=-1
      jca=kr
      do 779 if=1,ndet
      jca=jca+nod
      mal=jca
      do 780 nal=1,nod
      mal=mal+1
      if(ijog(nal).ne.jmat(mal)) go to 779
780   continue
      go to 781
779   continue
      go to 7781
781   mm=mm+1
      ot(mm)=if
      if(mm.lt.ibb) go to 782
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
782   mm=mm+1
      ot(mm)=nps
      if(mm.lt.ibb) go to 777
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
777   continue
751   continue
      go to 749
  752 do 790 m=1,kmj
      mm=mm+1
      ot(mm)=1
      if (mm.lt.ibb) go to 771
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  771 mm=mm+1
      ot(mm)=1
      if (mm.lt.ibb) go to 772
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  772 if (nod.eq.1) go to 790
      nps=0
      do 770 n=1,nod
      if (n.eq.k) go to 770
      nps=nps+1
      mm=mm+1
      if (mm.lt.ibb) go to 774
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  774 mm=mm+1
      ot(mm)=nps
      if (mm.lt.ibb) go to 770
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      mm=0
      jrec=jrec+nsz
  770 continue
  790 continue
749   continue
      if(mm.eq.0) go to 551
      call stopbk3
      call pack(lout,8,ot,ibb)
      call sttout3(jrec)
      jrec=jrec+nsz
551   continue
2     write(iwr,783)nmul,irec,jrec
      if(oprint(31))write (iwr,820) (jerk(i),i=1,mmax)
      if(oprint(31))write (iwr,820) (jbne(i),i=1,mmax)
c
      call stopbk3
c
      call clredx
      cpu=cpulft(1)
      write(iwr,9000)cpu ,charwall()
      return
950   write(iwr,952) kmj,nod
      go to 7781
951   write(iwr,953) kmj,ifac,nod
      go to 7781
954   write(iwr,957) ndet,nod
      go to 7781
955   write(iwr,958) ib,ndet,nmns
7781  call caserr('invalid parameters detected in table generator')
      return
7777  format(1x,104('=')//40x,35('*')/
     *40x,'Table-Ci -- table generation module'/
     *40x,35('*')/)
 900  format(2x,40i3)
241   format(/1x,'case : ',i2,5x,'nod = ',i2)
4320  format(2x,40i3)
4322  format(2x,15f8.4)
161   format(10x,'ier error=',i2)
 75   format(2x,20i6)
820   format(/10x,10i10/)
9000  format(/
     *1x,'**** end of table generation at ',f8.2,' seconds',
     + a10,' wall'/)
783   format(/5x,'end case ',3i10)
952   format(5x,'kmj too big',2i6)
953   format(5x,'kmj came out wrong',3i6)
957   format(5x,'ndet too big',2i6)
958   format(5x,'error in imat',3i6)
5544  format(1x,3i8)
      end
_IF(cray)
      subroutine pack12
      common/craypk/index(4000),ij(3)
c
      k=1
      do 1 i=1,3
      ii=ij(i)
      index(k  )=shiftr(ii,24).and.377b
      index(k+1)=shiftr(ii,16).and.377b
      index(k+2)=shiftr(ii, 8).and.377b
      index(k+3)=       ii    .and.377b
 1    k=k+4
      return
      end
_ELSEIF(ksr)
      subroutine pack12
      common/craypk/index(4000),ij(3)
c
      data m8/'ff'x/
      k=1
      do 1 i=1,3
      ii=ij(i)
      index(k  )=and(shiftr(ii,24),m8)
      index(k+1)=and(shiftr(ii,16),m8)
      index(k+2)=and(shiftr(ii, 8),m8)
      index(k+3)=and(       ii    ,m8)
 1    k=k+4
      return
      end
_ELSEIF(i88)
c     this code does NOT work becuse of -ve integers
      subroutine pack12
      implicit REAL  (a-h,o-z), integer (i-n)
      common/craypk/index(4000),ij(3)
c
      data m8/'ff'x/
      k=1
      do 1 i=1,3
      ii=ij(i)
      index(k  )=iand(ishft(ii,-24),m8)
      index(k+1)=iand(ishft(ii,-16),m8)
      index(k+2)=iand(ishft(ii,- 8),m8)
      index(k+3)=iand(      ii     ,m8)
 1    k=k+4
      return
      end
_ELSEIF(i8)
      subroutine pack12
      implicit REAL  (a-h,o-z), integer (i-n)
      logical *1 index,ij(12)
      integer *4 ic4, i24, i34
      common/craypk/index(32000),ic,i2,i3,ic4,i24,i34
      integer ot(4000)
      equivalence (ij(1),ic4),(index(1),ot(1))
      ic4 = ic
      i24 = i2
      i34 = i3
_IF(littleendian)
      i4=1
_ELSE
      i4=8
_ENDIF
      do 1 loop=1,12
      index(i4)=ij(loop)
  1   i4=i4+8
c
_IF()
      write(6,*)'**** pack12****'
      do loop=1,12
      write(6,92127) loop,ot(loop)
92127 format(1x,i3,2x,z16)
      enddo
_ENDIF
      return
      end
_ELSE
      subroutine pack12
      implicit REAL  (a-h,o-z), integer (i-n)
      logical *1 index,ij
      common/craypk/index(16000),ij(12)
_IF(littleendian)
      i4=1
_ELSE
      i4=4
_ENDIF
      do 1 loop=1,12
      index(i4)=ij(loop)
  1   i4=i4+4
      return
      end
_ENDIF
      subroutine dgelg(r,a,m,n,eps,ier)
_IF1()c****************************************************************
_IF1()c
_IF1()c   programmbibliothek rhrz bonn        28/11/78       dgelg
_IF1()c                                       fortran iv     ibm 370/168
_IF1()c
_IF1()c
_IF1()c name:    dgelg
c
c purpose:
c
c to solve a general system of simultaneous linear equations.
c
c usage:   call dgelg(r,a,m,n,eps,ier)
c
c parameters:
c
c r:       double precision m by n right hand side matrix
c          (destroyed). on return r contains the solutions
c          of the equations.
c
c a:       double precision m by m coefficient matrix
c          (destroyed).
c
c m:       the number of equations in the system.
c
c n:       the number of right hand side vectors.
c
c eps:     single precision input constant which is used as
c          relative tolerance for test on loss of
c          significance.
c
c ier:     resulting error parameter coded as follows
c           ier=0  - no error,
c           ier=-1 - no result because of m less than 1 or
c                   pivot element at any elimination step
c                   equal to 0,
c           ier=k  - warning due to possible loss of signifi-
c                   cance indicated at elimination step k+1,
c                   where pivot element was less than or
c                   equal to the internal tolerance eps times
c                   absolutely greatest element of matrix a.
c
c remarks: (1) input matrices r and a are assumed to be stored
c              columnwise in m*n resp. m*m successive storage
c              locations. on return solution matrix r is stored
c              columnwise too.
c          (2) the procedure gives results if the number of equations m
c              is greater than 0 and pivot elements at all elimination
c              steps are different from 0. however warning ier=k - if
c              given indicates possible loss of significance. in case
c              of a well scaled matrix a and appropriate tolerance eps,
c              ier=k may be interpreted that matrix a has the rank k.
c              no warning is given in case m=1.
c
c method:
c
c solution is done by means of gauss-elimination with
c complete pivoting.
c
c programs required:
c          none
_IF1()c
_IF1()c access:
_IF1()c
_IF1()c load module:    sys3.fortlib(dgelg)
_IF1()c source module:  sys3.symlib.fortran(dgelg)
_IF1()c description:    sys3.infolib(dgelg)
_IF1()c
_IF1()c author:         ibm, ssp iii
_IF1()c installation:   ibm 370/168, os-mvt, fortran iv (g).
_IF1()c
_IF1()c**********************************************************************
c
      implicit REAL (a-h,o-z), integer(i-n)
c
      dimension a(*),r(*)
      if(m)23,23,1
c
c     search for greatest element in matrix a
    1 ier=0
      piv=0.0d0
      mm=m*m
      nm=n*m
      do 3 l=1,mm
      tb=dabs(a(l))
      if(tb-piv)3,3,2
    2 piv=tb
      i=l
    3 continue
      tol=eps*piv
c     a(i) is pivot element. piv contains the absolute value of a(i).
c
c
c     start elimination loop
      lst=1
      do 17 k=1,m
c
c     test on singularity
      if(piv)23,23,4
    4 if(ier)7,5,7
    5 if(piv-tol)6,6,7
    6 ier=k-1
    7 pivi=1.0d0/a(i)
      j=(i-1)/m
      i=i-j*m-k
      j=j+1-k
c     i+k is row-index, j+k column-index of pivot element
c
c     pivot row reduction and row interchange in right hand side r
      do 8 l=k,nm,m
      ll=l+i
      tb=pivi*r(ll)
      r(ll)=r(l)
    8 r(l)=tb
c
c     is elimination terminated
      if(k-m)9,18,18
c
c     column interchange in matrix a
    9 lend=lst+m-k
      if(j)12,12,10
   10 ii=j*m
      do 11 l=lst,lend
      tb=a(l)
      ll=l+ii
      a(l)=a(ll)
   11 a(ll)=tb
c
c     row interchange and pivot row reduction in matrix a
   12 do 13 l=lst,mm,m
      ll=l+i
      tb=pivi*a(ll)
      a(ll)=a(l)
   13 a(l)=tb
c
c     save column interchange information
      a(lst)=j
c
c     element reduction and next pivot search
      piv=0.0d0
      lst=lst+1
      j=0
      do 16 ii=lst,lend
      pivi=-a(ii)
      ist=ii+m
      j=j+1
      do 15 l=ist,mm,m
      ll=l-j
      a(l)=a(l)+pivi*a(ll)
      tb=dabs(a(l))
      if(tb-piv)15,15,14
   14 piv=tb
      i=l
   15 continue
      do 16 l=k,nm,m
      ll=l+j
   16 r(ll)=r(ll)+pivi*r(l)
   17 lst=lst+m
c     end of elimination loop
c
c
c     back substitution and back interchange
   18 if(m-1)23,22,19
   19 ist=mm+m
      lst=m+1
      do 21 i=2,m
      ii=lst-i
      ist=ist-lst
      l=ist-m
      l=a(l)+0.5d0
      do 21 j=ii,nm,m
      tb=r(j)
      ll=j
      do 20 k=ist,mm,m
      ll=ll+1
   20 tb=tb-a(k)*r(ll)
      k=j+l
      r(j)=r(k)
   21 r(k)=tb
   22 return
c
c
c     error return
   23 ier=-1
      return
      end
      subroutine dmfgr(a,m,n,eps,irank,irow,icol)
_IF1()c****************************************************************
_IF1()c
_IF1()c                                      fortran iv     ibm 370/168
_IF1()c
_IF1()c
_IF1()c name:    dmfgr
_IF1()c
_IF1()c purpose:
c
c for a given m by n matrix the following calculations
c are performed
c (1) determine rank and linearly independent rows and
c     columns (basis).
c (2) factorize a submatrix of maximal rank.
c (3) express non-basic rows in terms of basic ones.
c (4) express basic variables in terms of free ones.
c
c usage:   call dmfgr(a,m,n,eps,irank,irow,icol)
c
c parameters:
c
c a:       double precision given matrix with m rows
c          and n columns.
c          on return a contains the triangular factors
c          of a submatrix of maximal rank.
c
c m:       number of rows of matrix a.
c
c n:       number of columns of matrix a.
c
c eps:     single precision testvalue for zero affected by
c          roundoff noise.
c
c irank:   resultant rank of given matrix.
c
c irow:    integer vector of dimension m containing the
c          subscripts of basic rows in irow(1),...,irow(irank)
c
c icol:    integer vector of dimension n containing the
c          subscripts of basic columns in icol(1) up to
c          icol(irank).
c
c remarks: the left hand triangular factor is normalized such that
c          the diagonal contains all ones thus allowing to store only
c          the subdiagonal part.
c
c method:
c
c gaussian elimination technique is used for calculation
c of the triangular factors of a given matrix.
c complete pivoting is built in.
c in case of a singular matrix only the triangular factors
c of a submatrix of maximal rank are retained.
c the remaining parts of the resultant matrix give the
c dependencies of rows and the solution of the homogeneous
c matrix equation a*x=0.
c
c programs required:
c          none
c
_IF1()c access:
_IF1()c
_IF1()c load module:    sys3.fortlib(dmfgr)
_IF1()c source module:  sys3.symlib.fortran(dmfgr)
_IF1()c description:    sys3.infolib(dmfgr)
_IF1()c
_IF1()c author:         ibm, ssp iii
_IF1()c installation:   ibm 370/168, os-mvt, fortran iv (g).
_IF1()c
_IF1()c****************************************************************
c
      implicit REAL (a-h,o-z), integer(i-n)
c        dimensioned dummy variables
      dimension a(*),irow(*),icol(*)
c
c        test of specified dimensions
      if(m)2,2,1
    1 if(n)2,2,4
    2 irank=-1
    3 return
c        return in case of formal errors
c
c
c        initialize column index vector
c        search first pivot element
    4 irank=0
      piv=0.0d0
      jj=0
      do 6 j=1,n
      icol(j)=j
      do 6 i=1,m
      jj=jj+1
      hold=a(jj)
      if(dabs(piv)-dabs(hold))5,6,6
    5 piv=hold
      ir=i
      ic=j
    6 continue
c
c        initialize row index vector
      do 7 i=1,m
    7 irow(i)=i
c
c        set up internal tolerance
      tol=dabs(eps*piv)
c
c        initialize elimination loop
      nm=n*m
      do 190 ncol=m,nm,m
c
c        test for feasibility of pivot element
_IF1()cpe    8 if(abs(piv)-tol)20,20,9
      if(dabs(piv)-tol)20,20,9
c
c        update rank
    9 irank=irank+1
c
c        interchange rows if necessary
      jj=ir-irank
      if(jj)12,12,10
   10 do 11 j=irank,nm,m
      i=j+jj
      save=a(j)
      a(j)=a(i)
   11 a(i)=save
c
c        update row index vector
      jj=irow(ir)
      irow(ir)=irow(irank)
      irow(irank)=jj
c
c        interchange columns if necessary
   12 jj=(ic-irank)*m
      if(jj)15,15,13
   13 kk=ncol
      do 14 j=1,m
      i=kk+jj
      save=a(kk)
      a(kk)=a(i)
      kk=kk-1
   14 a(i)=save
c
c        update column index vector
      jj=icol(ic)
      icol(ic)=icol(irank)
      icol(irank)=jj
   15 kk=irank+1
      mm=irank-m
      ll=ncol+mm
c
c        test for last row
      if(mm)16,25,25
c
c        transform current submatrix and search next pivot
   16 jj=ll
      save=piv
      piv=0.0d0
      do 191 j=kk,m
      jj=jj+1
      hold=a(jj)/save
      a(jj)=hold
      l=j-irank
c
c        test for last column
      if(irank-n) 17,191,191
   17 ii=jj
      do 19 i=kk,n
      ii=ii+m
      mm=ii-l
      a(ii)=a(ii)-hold*a(mm)
      if(dabs(a(ii))-dabs(piv))19,19,18
   18 piv=a(ii)
      ir=j
      ic=i
   19 continue
  191 continue
  190 continue
c
c        set up matrix expressing row dependencies
   20 if(irank-1)3,25,21
   21 ir=ll
      do 24 j=2,irank
      ii=j-1
      ir=ir-m
      jj=ll
      do 23 i=kk,m
      hold=0.0d0
      jj=jj+1
      mm=jj
      ic=ir
      do 22 l=1,ii
      hold=hold+a(mm)*a(ic)
      ic=ic-1
   22 mm=mm-m
   23 a(mm)=a(mm)-hold
   24 continue
c
c        test for column regularity
   25 if(n-irank)3,3,26
c
c        set up matrix expressing basic variables in terms of free
c        parameters (homogeneous solution).
   26 ir=ll
      kk=ll+m
      do 30 j=1,irank
      do 29 i=kk,nm,m
      jj=ir
      ll=i
      hold=0.0d0
      ii=j
   27 ii=ii-1
      if(ii)29,29,28
   28 hold=hold-a(jj)*a(ll)
      jj=jj-m
      ll=ll-1
      goto 27
   29 a(ll)=(hold-a(ll))/a(jj)
   30 ir=ir-1
      return
      end
      subroutine ver_mrdci5(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci5.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
