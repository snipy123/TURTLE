/*$Id: cg.c,v 1.1.1.1 2007-10-30 10:13:44 jmht Exp $*/
#include <stdio.h>
#include <math.h>
#include "armci.h"
#include <mpi.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#define PRINT_VEC_

#if defined(TCGMSG)
#   include <sndrcv.h>
    long tcg_tag =30000;
#   define MP_BARRIER()      SYNCH_(&tcg_tag)
#   define MP_INIT(arc,argv) PBEGIN_((argc),(argv))
#   define MP_FINALIZE()     PEND_()
#   define MP_MYID(pid)      *(pid)   = (int)NODEID_()
#   define MP_PROCS(pproc)   *(pproc) = (int)NNODES_()
#else
#   include <mpi.h>
#   define MP_BARRIER()      MPI_Barrier(MPI_COMM_WORLD)
#   define MP_FINALIZE()     MPI_Finalize()
#   define MP_INIT(arc,argv) MPI_Init(&(argc),&(argv))
#   define MP_MYID(pid)      MPI_Comm_rank(MPI_COMM_WORLD, (pid))
#   define MP_PROCS(pproc)   MPI_Comm_size(MPI_COMM_WORLD, (pproc));
#endif

int na,nz;
double *bvec,*dvec,*svec,*dmvec,*m_dvec,*amat,*xvec,*axvec,*rvec,*qvec;
int *ridx,*cidx;
int me, nproc;
int myfirstrow=0,mylastrow=0;
double epsilon=1e-4;
double time_get=0;
static int niter;
void read_and_create(int,char **);
void computeminverser(double *,double *, double *);
void computeminverse(double *,double *, int *,int *);
void finalize_arrays();
extern void acg_matvecmul(double *,double *,double *,int *,int *);
extern double acg_ddot(double *,double *);
void conjugate_gradient(int nit,int dopreconditioning)
{
int i,one=1,zero=0,negone=-1;
int lo,hi;
double d_one=1.0,d_zero=0.0,d_negone=-1.0;
double delta0=0.0,deltaold=0.0,deltanew=0.0,alpha=0.0,negalpha,beta,dtransposeq;
double time0;
int *mycp,*myrp;
int j;
double sum;

    acg_matvecmul(amat,xvec,axvec,ridx,cidx);             /* compute Ax */
#ifdef PRINT_VEC 
    acg_printvec("axvec",axvec);
    acg_printvec("bvec",bvec);
#endif
   
    acg_addvec(&d_one,bvec,&d_negone,axvec,rvec,ridx,cidx); /* r=b-Ax */
    
#ifdef PRINT_VEC 
    acg_printvec("rvec",rvec);
    if(me==0)for(i=0;i<nz;i++)printf("\n%d:col[%d]=%d",me,i,cidx[i]);
    fflush(stdout);
#endif

    if(dopreconditioning){
      computeminverse(dmvec,amat,ridx,cidx);
      /*acg_printvec("dmvec",dmvec);*/
      computeminverser(dmvec,rvec,dvec);
      /*acg_printvec("dvec",dvec);*/
      if (me == 0)
	printf("\nDoing preconditioning!\n");
    }
    else{
      if(me==0)memcpy(dvec,rvec,na*sizeof(double));
    }
    if(dopreconditioning)
      deltanew = acg_ddot(rvec,dvec);              /* deltanew = r.r_tranpose */
    else
      deltanew = acg_ddot(rvec,rvec);              /* deltanew = r.r_tranpose */

    delta0 = deltanew;                            /* delta0 = deltanew */

    if(me==0)printf("\n\tdelta0 is %f\n",delta0);

    for(i=0;i<nit && deltanew>(epsilon*epsilon*delta0);i++){
       acg_matvecmul(amat,dvec,qvec,ridx,cidx);   /* q = ad */

       dtransposeq=acg_ddot(dvec,qvec);            /* compute d_transpose.q */

       alpha = deltanew/dtransposeq;              /* deltanew/(d_transpose.q) */
#if 0
       if(i>0 && i%50==0){
         /* compute Ax*/
         acg_matvecmul(amat,xvec,axvec,ridx,cidx);
         /* x = x+ alpha.d*/ /* r=b-Ax*/
         acg_2addvec(&d_one,xvec,&alpha,dvec,xvec,&d_one,bvec,
                         &d_negone,axvec,rvec,ridx,cidx);
       }
       else
#endif
       {
         negalpha = 0.0-alpha;                         
         /* x = x+ alpha.d*/ /* r=r-alpha.q*/
         acg_2addvec(&d_one,xvec,&alpha,dvec,xvec,&d_one,rvec,
                         &negalpha,qvec,rvec,ridx,cidx);
       }

       if(dopreconditioning)
         computeminverser(dmvec,rvec,svec);

       deltaold = deltanew;                        /* deltaold = deltanew*/

       if(dopreconditioning)
         deltanew = acg_ddot(svec,rvec);           /* deltanew = r_transpose.r*/
       else
         deltanew = acg_ddot(rvec,rvec);           /* deltanew = r_transpose.r*/

       beta = deltanew/deltaold;                   /* beta = deltanew/deltaold*/

       if(dopreconditioning)
         acg_addvec(&d_one,svec,&beta,dvec,dvec,ridx,cidx); /* d = s + beta.d */
       else
         acg_addvec(&d_one,rvec,&beta,dvec,dvec,ridx,cidx); /* d = r + beta.d */

#ifdef PRINT_VEC 
       acg_printvec("xvec",xvec);
#endif
       //acg_printvec("xvec",xvec);

    }
    if(me==0)printf("\n\tIteration:%d\tBeta:%0.4f\tDelta:%f\n",i,beta,deltanew);
    niter = i;
}

void initialize_arrays(int dpc)
{
double d_one=1.0;
double d_ten=10.0;
double d_zero=0.0;
int i;
    for(i=0;i<na;i++){
      xvec[i]=0.0;
      dvec[i]=axvec[i]=rvec[i]=qvec[i]=0;
      if(dpc){dmvec[i]=svec[i]=0;}
    }
}

void finalize_arrays(int dpc)
{
    extern int ARMCI_Free(void*);
    if(me==0){
      ARMCI_Free(bvec);
      ARMCI_Free(dvec);
      ARMCI_Free(amat);
      ARMCI_Free(xvec);
      ARMCI_Free(axvec);
      ARMCI_Free(rvec);
      ARMCI_Free(qvec);
      ARMCI_Free(ridx);
      ARMCI_Free(cidx);
      if(dpc){
        ARMCI_Free(svec);
        ARMCI_Free(dmvec);
      }
    }
}     


FILE *fd;

int main(argc, argv)
int argc;
char **argv;
{
int dopreconditioning=1;
double time0,time1;
double d_one=1.0,d_zero=0.0,d_negone=-1.0;

    MP_INIT(arc,argv);
    MP_PROCS(&nproc);
    MP_MYID(&me);
    ARMCI_Init();                           /* initialize ARMCI */

    if(me==0)printf("\n                          CONJUGATE GRADIENT EXAMPLE\n");
    if(argc<3){
       if(me==0){
         printf(" CORRECT USAGE IS:");
         printf("\n\n <launch commands> cg.x na nz file");
         printf("\n\n where:");
         printf("\n\tna is array dimention (only square arrays supported)");
         printf("\n\tnz is number of non-zeros");
         printf("\n\tfile is either the input file or the word random");
         printf("\n\t  use the word random if you to use random input");
         printf("\n\t  input should be in row compressed format");
         printf("\n\t  file should have matrix a followed by row, col & b (Ax=b)");
         printf("\n\t  if file also has na and nz, pass them as 0's and the");
         printf("\n\t  program will read them from the file");
         printf("\n\nexample usages are:");
         printf("\n\tmpirun -np 4 ./ga_cg.x 5000 80000 /home/me/myinput.dat");
         printf("\n\tor");
         printf("\n\tmpirun -np 4 ./ga_cg.x 5000 80000 random\n\n");
         fflush(stdout);
       }
       ARMCI_Finalize();
       MPI_Finalize();
       return 0;
    }

    read_and_create(argc,argv);

    if(me==0)printf("\nWarmup and initialization run");
#if 0
    initialize_arrays(dopreconditioning);
    conjugate_gradient(1,dopreconditioning);
    time_get =0.0;
#endif
    if(me==0)printf("\n\nStarting Conjugate Gradient ....");
    initialize_arrays(dopreconditioning);
    time0=MPI_Wtime();
    conjugate_gradient(30000/*2*/,dopreconditioning);
    time1=MPI_Wtime();

    acg_matvecmul(amat,xvec,axvec,ridx,cidx);
    if(me==0)printf("\n%d:in %d iterations time to solution=%f-%f ax and b in cg_output.out\n",me,niter,(time1-time0),time_get);
    acg_matvecmul(amat,xvec,axvec,ridx,cidx);
    if(me==0){
      int i;
      fd = fopen("cg_output.out", "w");
      for(i=0;i<=na;i++)
        fprintf(fd,"\n%d:%s[%d]=%f %s[%d]=%f",me,"bvec",i,bvec[i],"axvec",i,axvec[i]);
      fflush(stdout);
      fclose(fd);
    }

    finalize_arrays(dopreconditioning);
    MPI_Barrier(MPI_COMM_WORLD);

    if(me==0)printf("Terminating ..\n");
    ARMCI_Finalize();
    MPI_Finalize();
    return 0;
}

