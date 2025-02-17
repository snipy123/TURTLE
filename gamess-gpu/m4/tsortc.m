_IF(win95)
_IF(ifc)
#define openc_ OPENC
#define closec_ CLOSEC
#define ver_tsortc_ VER_TSORTC
#define wrabsf_ WRABSF
#define rdabsf_ RDABSF
#define dfilec_ DFILEC
_ELSE
#pragma aux closec "^"
#pragma aux rdabsf "^"
#pragma aux wrabsf "^"
#pragma aux dfilec "^"
#pragma aux ver_tsortc "^"
#define NOC_
_ENDIF
_ENDIF

/* Utility routines for molpro88 unix version

  modified ps - 
     use #define to control _ appends
     use function prototypes on all platforms


I/O routines:	openc(unit,fname,size,status)
		character*(*) fname
		integer unit,size,status
			open file fname with unit number unit
			integer status codes as defined below

		closec(unit)

		rdabsf(unit,a,l,p)
		wrabsf(unit,a,l,p)
		integer unit,l,p
		double precision a
		read,write respectively l words on unit with buffer a at
		offset p words relative to beginning of file
		all counting done in double words

*/

#ifdef CRAYXX
#define openc_ OPENC
#define closec_ CLOSEC
#define rdabsf_ RDABSF
#define wrabsf_ WRABSF
#define dfilec_ DFILEC
#define ver_tsortc_ VER_TSORTC
#endif

#ifdef NOC_
#define openc_ openc
#define closec_ closec
#define rdabsf_ rdabsf
#define wrabsf_ wrabsf
#define dfilec_ dfilec
#define ver_tsortc_ ver_tsortc
#endif


#ifdef LINUXF2C
#define ver_tsortc_ ver_tsortc__
#endif

#ifdef GFS
#define ver_tsortc ver_tsortc_
#endif

_IFN(vms)
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
_IF(osf,convex)
#include <sys/file.h>
_ELSE
#include <fcntl.h>
_ENDIF

_IF(win95)
#include <io.h>
#include <process.h>    /* for getpid */
#include <stdlib.h>
#include <time.h>
#include <string.h>
_ELSE
#include <sys/times.h>
#include <sys/param.h>
_ENDIF

_ELSE
#include <stat.h>
#include <signal.h>
#include <math.h>
#include <stdlib.h>
#include <file.h>
#include <stdio.h>
#include <unixio.h>
#include <unixlib.h>
#include <string.h>
#include <errno.h>
_ENDIF(vms)

#ifdef LONG_INTEGER
#define int long
#endif

extern char  *getenv(); 
#define SEEK		0.015		/* average seektime in seconds */
#define SPEED		307250		/* speed in words per second */

#define MAXLENGTH	80
#define MAXUNIT		99
#ifdef LONG_INTEGER
#define NBPI	        8	
#else
#define NBPI	        4	
#endif

#define PATHMAX         512 
#define UNKNOWN		1
#define SCRATCH		0
#define NEW		2
#define OLD		3

/* Function Prototypes */

_IFN(win95)
void openc(int *unit, char *fname, int *size, int *status, int *nchar);
void wrabsf(int *unit, char *a, int *l, int*p);
void rdabsf(int *unit, char *a, int *l, int*p);
void closec(int *unit);
void dfilec(int *unit);
_ENDIF


typedef struct
{ long  fd, addr, size;
  char fname[80];
} FILE_DEFINITION;

FILE_DEFINITION cfiles[MAXUNIT];
int nwords=0, nio=0;

_IFN1(d)void openc_(unit,fname,size,status,nchar)
_IF(dec)
_IFN(vms)
void openc_(unit,fname,size,status,nchar)
  int *unit, *size, *status; char *fname;int *nchar;
_ELSE
void openc(int* unit, char *fname, int *size, int *status, int *nchar)
_ENDIF
_ENDIF
_IFN(dec)
  int *unit, *size, *status; char *fname;int *nchar;
_ENDIF

{ char *cp, *env ;
  char  name[PATHMAX]; 
  char *tit_nullt();

  if (*unit>MAXUNIT || *unit<0)
	{ fprintf(stderr,"openc: Unit number out of range (%d)\n",*unit);
	  exit(20);
	}
  fname = tit_nullt(fname,*nchar);
/*  printf("filename after tit_nullt ---%s----\n",fname);*/
  if (strlen(fname)-1>MAXLENGTH)
  fprintf(stderr,"openc: filename too long >79\n");
  strcpy(name,fname); 
  if((env=getenv(fname)) !=NULL) 
  strcpy(name,env); 
/*  printf("name after env ---%s----\n",name); */

  switch(*status)
{ case SCRATCH:	sprintf(cfiles[*unit].fname,"Tmp%d",getpid());
_IFN(win95)
		cfiles[*unit].fd=open(name,O_RDWR|O_CREAT,0666);
_ELSE
		cfiles[*unit].fd=open(name,O_RDWR|O_CREAT|O_BINARY,0666);
_ENDIF
		unlink(cfiles[*unit].fname);
		break;
_IFN(win95)
  case UNKNOWN:	if ((cfiles[*unit].fd=open(name,O_RDWR|O_CREAT,0666))==-1)
_ELSE
  case UNKNOWN:	if ((cfiles[*unit].fd=open(name,O_RDWR|O_CREAT|O_BINARY,0666))==-1)
_ENDIF
		{ fprintf(stderr,"openc: Error in opening file %s\n",fname);
				  exit(1);
				}
		break;
_IFN(win95)
  case NEW:	if ((cfiles[*unit].fd=open(name,O_RDWR|O_CREAT|O_TRUNC,0666))==-1)
_ELSE
  case NEW:	if ((cfiles[*unit].fd=open(name,O_RDWR|O_CREAT|O_TRUNC|O_BINARY,0666))==-1)
_ENDIF
			{ fprintf(stderr,"openc: Error in opening file %s\n",fname);
			  exit(1);
			}
		break;
_IFN(win95)
  case OLD:	if ((cfiles[*unit].fd=open(name,O_RDWR))==-1)
_ELSE
  case OLD:	if ((cfiles[*unit].fd=open(name,O_RDWR|O_BINARY))==-1)
_ENDIF
			{ fprintf(stderr,"openc: Error in opening file %s\n",fname);
			  exit(1);
			}
		break;
  default:	fprintf(stderr,"openc: Unknown status\n"); exit(1);
}
  cfiles[*unit].size= *size;
  strncpy(cfiles[*unit].fname,fname,79); *(cfiles[*unit].fname+79)='\0';
  *size=(lseek(cfiles[*unit].fd,0L,2)+511)/512;
  cfiles[*unit].addr= -1;
}

_IFN1(d)void wrabsf_(unit,a,l,p) int *unit, *l, *p; char *a;
_IF(dec)
_IFN(vms)
void wrabsf_(unit,a,l,p) int *unit, *l, *p; char *a;
_ELSE
void wrabsf(int* unit, char *a, int *l, int *p)
_ENDIF
_ENDIF

_IFN(osf)
{ long addr, m, n;
_ELSE
{ int addr, m, n;
_ENDIF

  if (*unit>MAXUNIT || *unit<0)
	{ fprintf(stderr,"wrabs: Unit number out of range (%d)\n",*unit);
	  exit(20);
	}
  if (!*cfiles[*unit].fname)
	{ fprintf(stderr,"wrabs: write without open file unit=%d\n",*unit);
	  exit(20);
	}
  m = *p;
  addr= m * NBPI;
  m = *l;
  m= m * NBPI;
/*  fprintf(stderr,"name %s \n",cfiles[*unit].fname);
  fprintf(stderr,"open %d \n",cfiles[*unit].fd);
  fprintf(stderr,"current address %d \n",cfiles[*unit].addr);
  fprintf(stderr,"request address %d \n",addr);*/
  if (addr!=cfiles[*unit].addr)
	if (lseek(cfiles[*unit].fd,(off_t)addr,0)==-1)
	{ fprintf(stderr,"wrabs: Error lseek (%d:%s) pointer=%d\n",
                  *unit,cfiles[*unit].fname,*p);
	  cfiles[*unit].addr= -1;
	  exit(20);
	}
  if ((n=write (cfiles[*unit].fd,a,m))!=m)
   {fprintf(stderr,"wrabs: Error writing %d to file %s  unit %d\n",
	            *p,cfiles[*unit].fname,*unit);
    fprintf(stderr,"wrabs: n %d  m %d\n",n,m);
    exit(20);
  }
  nio++; nwords+= *l;
  cfiles[*unit].addr=addr+n;
}

_IFN1(d)void rdabsf_(unit,a,l,p) int *unit, *l, *p; char *a;
_IF(dec)
_IFN(vms)
void rdabsf_(unit,a,l,p) int *unit, *l, *p; char *a;
_ELSE
void rdabsf(int* unit, char *a, int *l, int *p)
_ENDIF
_ENDIF

_IFN(osf)
{ long addr, m, n;
_ELSE
{ int addr, m, n;
_ENDIF

  if (*unit>MAXUNIT || *unit<0)
	{ fprintf(stderr,"rdabs: Unit number out of range (%d)\n",*unit);
	  exit(20);
	}
  if (!*cfiles[*unit].fname)
	{ fprintf(stderr,"rdabs: write without open file unit=%d\n",*unit);
	  exit(20);
	}
  m = *p;
  addr= m * NBPI;
  m = *l;
  m= m *NBPI;
  if (addr!=cfiles[*unit].addr)
	if (lseek(cfiles[*unit].fd,(off_t)addr,0)==-1)
	{ fprintf(stderr,"rdabs: Error in lseek of (%d:%s) -> pointer=%d\n",*unit,cfiles[*unit].fname,*p);
	  cfiles[*unit].addr= -1;
	  exit(20);
	}
  if ((n=read (cfiles[*unit].fd,a,m))!=m)
	{fprintf(stderr,"rdabs: Error reading %d file %s with unit %d\n",
                 *p,cfiles[*unit].fname,*unit);
         exit(20);
       }
  nio++; nwords+= *l;
  cfiles[*unit].addr=addr+n;
}

_IFN1(d)void closec_(unit) int *unit;
_IF(dec)
_IFN(vms)
void closec_(unit) int *unit;
_ELSE
void closec(int* unit)
_ENDIF
_ENDIF

{ if (*unit>MAXUNIT || *unit<0)
	{ fprintf(stderr,"closec: unit out of range\n"); exit(20); }
  if (cfiles[*unit].fd)
	{ close(cfiles[*unit].fd);
	  cfiles[*unit].fd=cfiles[*unit].addr=cfiles[*unit].size=0;
	  *cfiles[*unit].fname='\0';
	}
  return;
}

_IFN1(d)void dfilec_(unit) int *unit;
_IF(dec)
_IFN(vms)
void dfilec_(unit) int *unit;
_ELSE
void dfilec(int* unit)
_ENDIF
_ENDIF

{ if (*unit>MAXUNIT || *unit<0)
	{ fprintf(stderr,"dfilec: unit out of range\n"); exit(20); }
  if (cfiles[*unit].fd)
	{ close(cfiles[*unit].fd);
 	  unlink(cfiles[*unit].fname);
	  cfiles[*unit].fd=cfiles[*unit].addr=cfiles[*unit].size=0;
	  *cfiles[*unit].fname='\0';
	}
  return;
}
/********************************************************************
 * tit_nullt(s,n) null terminate a string from FORTRAN, and copy it
 ********************************************************************/
 char *tit_nullt(s,n)
   char *s;
   int n;
{
   int i;
   char *t;
_IFN(win95)
   char *malloc();
_ENDIF
	  for(i = n - 1; *(s+i) == ' ' && i; i--)
	      ;
     
 t = malloc(sizeof(char) * (i+2)); 
 strncpy(t,s,i+1);
 *(t+i+1) = '\0';
  return t;
}

char source[]="$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/tsortc.m,v $";
char revision[]="$Revision: 5733 $";
char date[]="$Date: 2008-10-06 23:36:09 +0200 (Mon, 06 Oct 2008) $";

void ver_tsortc_( char *string1, int *length1, char *string2, int *length2,char *string3, int *length3)
{
  int l, start;
  l = strlen(source);
  start = 8;
  l-=start;
  if(l > *length1)l = *length1;
  strncpy(string1,source+start,l);

  l = strlen(revision);
  start = 10;
  l-=start;
  if(l > *length2)l = *length2;
  strncpy(string2,revision+start,l);

  l = strlen(date);
  start = 6;
  l-=start;
  if(l > *length3)l = *length3;
  strncpy(string3,date+start,l);
}  

