/* $Id: capi.c,v 1.1.1.8 2007-10-30 10:13:59 jmht Exp $ */
#include "ga.h"
#include "globalp.h"
#include <stdio.h>
#include <stdlib.h>

Integer _ga_lo[MAXDIM], _ga_hi[MAXDIM], _ga_work[MAXDIM];
Integer _ga_dims[MAXDIM], _ga_map_capi[MAX_NPROC];
Integer _ga_width[MAXDIM];
Integer _ga_skip[MAXDIM];

Integer _ga_alo[MAXDIM], _ga_ahi[MAXDIM];
Integer _ga_blo[MAXDIM], _ga_bhi[MAXDIM];
Integer _ga_clo[MAXDIM], _ga_chi[MAXDIM];
Integer _ga_mlo[MAXDIM], _ga_mhi[MAXDIM];

Integer _ga_xxlo[MAXDIM], _ga_xxhi[MAXDIM];
Integer _ga_vvlo[MAXDIM], _ga_vvhi[MAXDIM];
Integer _ga_xxlllo[MAXDIM], _ga_xxllhi[MAXDIM];
Integer _ga_xxuulo[MAXDIM], _ga_xxuuhi[MAXDIM];

short int _ga_irreg_flag = 0;

#ifdef USE_FAPI
#  define COPYC2F(carr, farr, n){\
   int i; for(i=0; i< (n); i++)(farr)[i]=(Integer)(carr)[i];} 
#  define COPYF2C(farr, carr, n){\
   int i; for(i=0; i< (n); i++)(carr)[i]=(int)(farr)[i];} 
#  define COPYF2C_64(farr, carr, n){\
   int i; for(i=0; i< (n); i++)(carr)[i]=(int64_t)(farr)[i];} 
#else
#  define COPYC2F(carr, farr, n){\
   int i; for(i=0; i< (n); i++)(farr)[n-i-1]=(Integer)(carr)[i];} 
#  define COPYF2C(farr, carr, n){\
   int i; for(i=0; i< (n); i++)(carr)[n-i-1]=(int)(farr)[i];} 
#  define COPYF2C_64(farr, carr, n){\
   int i; for(i=0; i< (n); i++)(carr)[n-i-1]=(int64_t)(farr)[i];} 
#define BASE_0
#endif

#define COPY(CAST,src,dst,n) {\
   int i; for(i=0; i< (n); i++)(dst)[i]=(CAST)(src)[i];} 

#ifdef BASE_0 
#  define COPYINDEX_C2F(carr, farr, n){\
   int i; for(i=0; i< (n); i++)(farr)[n-i-1]=(Integer)(carr)[i]+1;}
#  define COPYINDEX_F2C(farr, carr, n){\
   int i; for(i=0; i< (n); i++)(carr)[n-i-1]=(int)(farr)[i] -1;}
#  define COPYINDEX_F2C_64(farr, carr, n){\
   int i; for(i=0; i< (n); i++)(carr)[n-i-1]=(int64_t)(farr)[i] -1;}
#else
#  define COPYINDEX_F2C     COPYF2C
#  define COPYINDEX_F2C_64  COPYF2C_64
#  define COPYINDEX_C2F     COPYC2F
#endif

int GA_Uses_fapi(void)
{
#ifdef USE_FAPI
return 1;
#else
return 0;
#endif
}


void GA_Initialize_ltd(size_t limit)
{
Integer lim = (Integer)limit;
     ga_initialize_ltd_(&lim);
}

int NGA_Create(int type, int ndim,int dims[], char *name, int *chunk)
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create((Integer)type, (Integer)ndim, _ga_dims, name, ptr, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create64(int type, int ndim,int64_t dims[], char *name, int64_t *chunk)
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create((Integer)type, (Integer)ndim, _ga_dims, name, ptr, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_config(int type, int ndim,int dims[], char *name, int chunk[],
                      int p_handle)
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create_config((Integer)type, (Integer)ndim, _ga_dims, name, ptr,
                    (Integer)p_handle, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}


int NGA_Create_config64(int type, int ndim,int64_t dims[], char *name, int64_t chunk[],
                      int p_handle)
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create_config((Integer)type, (Integer)ndim, _ga_dims, name, ptr,
                    (Integer)p_handle, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_irreg(int type,int ndim,int dims[],char *name,int block[],int map[])
{
    Integer *ptr, g_a;
    logical st;
    int d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif
      
     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_irreg(type, (Integer)ndim, _ga_dims, name, ptr, _ga_work, &g_a);
     _ga_irreg_flag = 0; /* unset it after creating the array */

    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_irreg64(int type,int ndim,int64_t dims[],char *name,int64_t block[],int64_t map[])
{
    Integer *ptr, g_a;
    logical st;
    int64_t d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif
      
     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_irreg(type, (Integer)ndim, _ga_dims, name, ptr, _ga_work, &g_a);
     _ga_irreg_flag = 0; /* unset it after creating the array */

    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_irreg_config(int type,int ndim,int dims[],char *name,int block[],
                            int map[], int p_handle)
{
    Integer *ptr, g_a;
    logical st;
    int d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif

     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_irreg_config(type, (Integer)ndim, _ga_dims, name, ptr,
				  _ga_work, (Integer)p_handle, &g_a);
     _ga_irreg_flag = 0; /* unset it, after creating array */

    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_irreg_config64(int type,int ndim,int64_t dims[],char *name,int64_t block[],
                            int64_t map[], int p_handle)
{
    Integer  *ptr, g_a;
    logical st;
    int64_t d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif

     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_irreg_config(type, (Integer)ndim, _ga_dims, name, ptr,
				  _ga_work, (Integer)p_handle, &g_a);
     _ga_irreg_flag = 0; /* unset it, after creating array */

    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts_irreg(int type,int ndim,int dims[],int width[],char *name,
    int block[],int map[])
{
    Integer *ptr, g_a;
    logical st;
    int d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);
    COPYC2F(width,_ga_width, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif
     
     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_ghosts_irreg(type, (Integer)ndim, _ga_dims, _ga_width, 
				  name, ptr, _ga_work, &g_a);
     _ga_irreg_flag = 0; /* unset it, after creating array */ 
     
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts_irreg64(int type,int ndim,int64_t dims[],int64_t width[],char *name,
    int64_t block[],int64_t map[])
{
    Integer *ptr, g_a;
    logical st;
    int64_t d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);
    COPYC2F(width,_ga_width, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif
     
     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_ghosts_irreg(type, (Integer)ndim, _ga_dims, _ga_width, 
				  name, ptr, _ga_work, &g_a);
     _ga_irreg_flag = 0; /* unset it, after creating array */ 
     
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts_irreg_config(int type, int ndim, int dims[], int width[],
    char *name, int block[], int map[], int p_handle)
{
    Integer *ptr, g_a;
    logical st;
    int d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);
    COPYC2F(width,_ga_width, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif

     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_ghosts_irreg_config(type, (Integer)ndim, _ga_dims,
					 _ga_width, name, ptr, _ga_work, 
					 (Integer)p_handle, &g_a);
     _ga_irreg_flag = 0; /* unset it, after creating array */ 

    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts_irreg_config64(int type, int ndim, int64_t dims[], int64_t width[],
    char *name, int64_t block[], int64_t map[], int p_handle)
{
    Integer *ptr, g_a;
    logical st;
    int64_t d, base_map=0, base_work, b;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(block,_ga_work, ndim);
    COPYC2F(width,_ga_width, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
        base_work = 0;
#else
        base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
        base_work -= block[d];
        if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

            _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
            _ga_map_capi[base_work + b]++;
#endif
        }
        base_map += block[d];

#ifdef  USE_FAPI
        base_work += block[d];
        if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
     }

#ifdef  USE_FAPI
     ptr = _ga_map_capi;
#else
     ptr = _ga_map_capi + base_work;
#endif

     _ga_irreg_flag = 1; /* set this flag=1, to indicate array is irregular */
     st = nga_create_ghosts_irreg_config(type, (Integer)ndim, _ga_dims,
					 _ga_width, name, ptr, _ga_work, 
					 (Integer)p_handle, &g_a);
     _ga_irreg_flag = 0; /* unset it, after creating array */ 

    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts(int type, int ndim,int dims[], int width[], char *name,
    int chunk[])
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(width,_ga_width, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create_ghosts((Integer)type, (Integer)ndim, _ga_dims,
        _ga_width, name, ptr, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts64(int type, int ndim, int64_t dims[], int64_t width[], char *name,
    int64_t chunk[])
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(width,_ga_width, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create_ghosts((Integer)type, (Integer)ndim, _ga_dims,
        _ga_width, name, ptr, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts_config(int type, int ndim,int dims[], int width[], char *name,
    int chunk[], int p_handle)
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(width,_ga_width, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create_ghosts_config((Integer)type, (Integer)ndim, _ga_dims,
        _ga_width, name, ptr, (Integer)p_handle, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int NGA_Create_ghosts_config64(int type, int ndim,int64_t  dims[], int64_t width[], char *name,
    int64_t chunk[], int p_handle)
{
    Integer *ptr, g_a; 
    logical st;
    if(ndim>MAXDIM)return 0;

    COPYC2F(dims,_ga_dims, ndim);
    COPYC2F(width,_ga_width, ndim);
    if(!chunk)ptr=(Integer*)0;  
    else {
         COPYC2F(chunk,_ga_work, ndim);
         ptr = _ga_work;
    }
    st = nga_create_ghosts_config((Integer)type, (Integer)ndim, _ga_dims,
        _ga_width, name, ptr, (Integer)p_handle, &g_a);
    if(st==TRUE) return (int) g_a;
    else return 0;
}

int GA_Create_handle()
{
    Integer g_a;
    g_a = ga_create_handle_();
    return (int)g_a;
}

void GA_Set_data(int g_a, int ndim, int dims[], int type)
{
    Integer aa, nndim, ttype;
    COPYC2F(dims,_ga_dims, ndim);
    aa = (Integer)g_a;
    nndim = (Integer)ndim;
    ttype = (Integer)type;
    ga_set_data_(&aa, &nndim, _ga_dims, &ttype);
}

void GA_Set_data64(int g_a, int ndim, int64_t dims[], int type)
{
    Integer aa, nndim, ttype;
    COPYC2F(dims,_ga_dims, ndim);
    aa = (Integer)g_a;
    nndim = (Integer)ndim;
    ttype = (Integer)type;
    ga_set_data_(&aa, &nndim, _ga_dims, &ttype);
}

void GA_Set_chunk(int g_a, int chunk[])
{
    Integer aa, *ptr, ndim;
    aa = (Integer)g_a;
    ndim = ga_get_dimension_(&aa);
    if(!chunk)ptr=(Integer*)0;  
    else {
      COPYC2F(chunk,_ga_work, ndim);
      ptr = _ga_work;
    }
    ga_set_chunk_(&aa, ptr);
}

void GA_Set_chunk64(int g_a, int64_t chunk[])
{
    Integer aa, *ptr, ndim;
    aa = (Integer)g_a;
    ndim = ga_get_dimension_(&aa);
    if(!chunk)ptr=(Integer*)0;  
    else {
      COPYC2F(chunk,_ga_work, ndim);
      ptr = _ga_work;
    }
    ga_set_chunk_(&aa, ptr);
}

void GA_Set_array_name(int g_a, char *name)
{
    Integer aa;
    aa = (Integer)g_a;
    ga_set_array_name(aa, name);
}

void GA_Set_pgroup(int g_a, int p_handle)
{
  Integer aa, pp;
  aa = (Integer)g_a;
  pp = (Integer)p_handle;
  ga_set_pgroup_(&aa, &pp);
}

void GA_Set_block_cyclic(int g_a, int dims[])
{
    Integer aa, ndim;
    aa = (Integer)g_a;
    ndim = ga_get_dimension_(&aa);
    COPYC2F(dims,_ga_dims, ndim);
    ga_set_block_cyclic_(&aa, _ga_dims);
}

int GA_Total_blocks(int g_a)
{
    Integer aa;
    aa = (Integer)g_a;
    return (int)ga_total_blocks_(&aa);
}

void GA_Get_proc_index(int g_a, int iproc, int index[])
{
     Integer aa, proc, ndim;
     aa = (Integer)g_a;
     proc = (Integer)iproc;
     ndim = ga_get_dimension_(&aa);
     ga_get_proc_index_(&aa, &proc, _ga_work);
     COPYF2C(_ga_work,index, ndim);
}

void GA_Get_block_info(int g_a, int num_blocks[], int block_dims[])
{
     Integer aa, ndim;
     aa = (Integer)g_a;
     ndim = ga_get_dimension_(&aa);
     ga_get_block_info_(&aa, _ga_work, _ga_lo);
     COPYF2C(_ga_work,num_blocks, ndim);
     COPYF2C(_ga_lo,block_dims, ndim);
}

void GA_Set_block_cyclic_proc_grid(int g_a, int block[], int proc_grid[])
{
    Integer aa, ndim;
    aa = (Integer)g_a;
    ndim = ga_get_dimension_(&aa);
    COPYC2F(block,_ga_dims, ndim);
    COPYC2F(proc_grid,_ga_lo, ndim);
    ga_set_block_cyclic_proc_grid_(&aa, _ga_dims, _ga_lo);
}

int GA_Get_pgroup(int g_a)
{
    Integer aa;
    aa = (Integer)g_a;
    return (int)ga_get_pgroup_(&aa);
}

void GA_Set_ghosts(int g_a, int width[])
{
    Integer aa, *ptr, ndim;
    aa = (Integer)g_a;
    ndim = ga_get_dimension_(&aa);
    if(!width)ptr=(Integer*)0;  
    else {
      COPYC2F(width,_ga_work, ndim);
      ptr = _ga_work;
    }
    ga_set_ghosts_(&aa, ptr);
}

void GA_Set_ghosts64(int g_a, int64_t width[])
{
    Integer aa, *ptr, ndim;
    aa = (Integer)g_a;
    ndim = ga_get_dimension_(&aa);
    if(!width)ptr=(Integer*)0;  
    else {
      COPYC2F(width,_ga_work, ndim);
      ptr = _ga_work;
    }
    ga_set_ghosts_(&aa, ptr);
}

void GA_Set_irreg_distr_(int g_a, int map[], int block[])
{
    Integer aa, *ptr, ndim;
    int d, base_map=0, base_work, b;
    aa = (Integer)g_a;
    ndim = ga_get_dimension_(&aa);
    COPYC2F(block,_ga_work, ndim);

    /* copy might swap only order of dimensions for blocks in map */
#ifdef  USE_FAPI
    base_work = 0;
#else
    base_work =MAX_NPROC;
#endif

    for(d=0; d<ndim; d++){
#ifndef  USE_FAPI
      base_work -= block[d];
      if(base_work <0)GA_Error("GA C api: error in block",d);
#endif
        for(b=0; b<block[d]; b++){

          _ga_map_capi[base_work + b] = (Integer)map[base_map +b]; /*****/
#ifdef BASE_0
          _ga_map_capi[base_work + b]++;
#endif
      }
      base_map += block[d];
#ifdef  USE_FAPI
      base_work += block[d];
      if(base_work >MAX_NPROC)GA_Error("GA (c): error in block",base_work);
#endif
   }

#ifdef  USE_FAPI
   ptr = _ga_map_capi;
#else
   ptr = _ga_map_capi + base_work;
#endif
   ga_set_irreg_distr_(&aa, ptr, _ga_work);
}

void GA_Set_irreg_flag(int g_a, int flag)
{
  Integer aa;
  logical fflag;
  aa = (Integer)g_a;
  fflag = (logical)flag;
  ga_set_irreg_flag_(&aa, &fflag);
}

void GA_Set_ghost_corner_flag(int g_a, int flag)
{
  Integer aa;
  logical fflag;
  aa = (Integer)g_a;
  fflag = (logical)flag;
  ga_set_ghost_corner_flag_(&aa, &fflag);
}

int GA_Get_dimension(int g_a)
{
  Integer aa;
  aa = (Integer)g_a;
  return (int)ga_get_dimension_(&aa);
}

int GA_Allocate(int g_a)
{
  Integer aa;
  aa = (Integer)g_a;
  return (int)ga_allocate_(&aa);
}

int GA_Pgroup_nodeid(int grp_id)
{
    Integer agrp_id = (Integer)grp_id;
    return (int)ga_pgroup_nodeid_(&agrp_id);
}

int GA_Pgroup_nnodes(int grp_id)
{
    Integer agrp_id = (Integer)grp_id;
    return (int)ga_pgroup_nnodes_(&agrp_id);
}

int GA_Pgroup_create(int *list, int count)
{
    Integer acount = (Integer)count;
    int i;
    for (i=0; i<count; i++)
       _ga_map_capi[i] = (Integer)list[i];
    return (int)ga_pgroup_create_(_ga_map_capi,&acount);
}

int GA_Pgroup_destroy(int grp)
{
    Integer grp_id = (Integer)grp;
    return (int)ga_pgroup_destroy_(&grp_id);
}

int GA_Pgroup_split(int grp_id, int num_group)
{
    Integer anum = (Integer)num_group;
    Integer grp  = (Integer)grp_id;
    return (int)ga_pgroup_split_(&grp, &anum);
}

int GA_Pgroup_split_irreg(int grp_id, int color, int key)
{
    Integer acolor = (Integer)color;
    Integer akey = (Integer)key;
    Integer grp  = (Integer)grp_id;
    return (int)ga_pgroup_split_irreg_(&grp, &acolor, &akey);
}

void GA_Update_ghosts(int g_a)
{
    Integer a=(Integer)g_a;
    ga_update_ghosts_(&a);
}

void GA_Merge_mirrored(int g_a)
{
    Integer a=(Integer)g_a;
    ga_merge_mirrored_(&a);
}

void GA_Fast_merge_mirrored(int g_a)
{
    Integer a=(Integer)g_a;
    ga_fast_merge_mirrored_(&a);
}

int GA_Is_mirrored(int g_a)
{
    Integer a=(Integer)g_a;
    return (int)ga_is_mirrored_(&a);
}

int GA_Num_mirrored_seg(int g_a)
{
    Integer a=(Integer)g_a;
    return (int)ga_num_mirrored_seg_(&a);
}

void GA_Get_mirrored_block(int g_a, int nblock, int *lo, int *hi)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    Integer nn=(Integer)nblock;

    ga_get_mirrored_block_(&a, &nn, _ga_alo, _ga_ahi);

    COPYINDEX_F2C(_ga_lo, lo, ndim);
    COPYINDEX_F2C(_ga_hi, hi, ndim);
    return;
}

void GA_Get_mirrored_block64(int g_a, int nblock, int64_t *lo, int64_t *hi)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    Integer nn=(Integer)nblock;

    ga_get_mirrored_block_(&a, &nn, _ga_alo, _ga_ahi);

    COPYINDEX_F2C_64(_ga_lo, lo, ndim);
    COPYINDEX_F2C_64(_ga_hi, hi, ndim);
    return;
}

void NGA_Merge_distr_patch(int g_a, int *alo, int *ahi,
                          int g_b, int *blo, int *bhi)
{
    Integer a = (Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    nga_merge_distr_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi);
}

void NGA_Merge_distr_patch64(int g_a, int64_t *alo, int64_t *ahi,
                             int g_b, int64_t *blo, int64_t *bhi)
{
    Integer a = (Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    nga_merge_distr_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi);
}

int NGA_Update_ghost_dir(int g_a, int dimension, int dir, int flag)
{
    Integer a=(Integer)g_a;
    Integer idim = (Integer)dimension;
    Integer idir = (Integer)dir;
    logical iflag = (logical)flag;
    logical st;
    idim++;
    st = nga_update_ghost_dir_(&a,&idim,&idir,&iflag);
    return (int)st;
}

void NGA_NbGet_ghost_dir(int g_a, int mask[], ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(mask,_ga_lo, ndim);
    nga_nbget_ghost_dir_(&a, _ga_lo,(Integer *)nbhandle);
}

void NGA_NbGet_ghost_dir64(int g_a, int64_t mask[], ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(mask,_ga_lo, ndim);
    nga_nbget_ghost_dir_(&a, _ga_lo,(Integer *)nbhandle);
}

int GA_Has_ghosts(int g_a)
{
    Integer a=(Integer)g_a;
    logical st;
    st = ga_has_ghosts_(&a);
    return (int)st;
}

void GA_Mask_sync(int first, int last)
{
    Integer ifirst = (Integer)first;
    Integer ilast = (Integer)last;
    ga_mask_sync_(&ifirst,&ilast);
}

int GA_Duplicate(int g_a, char* array_name)
{
    logical st;
    Integer a=(Integer)g_a, b;
    st = ga_duplicate(&a, &b, array_name);
    if(st==TRUE) return (int) b;
    else return 0;
}


void GA_Destroy(int g_a)
{
    logical st;
    Integer a=(Integer)g_a;
    st = ga_destroy_(&a);
    if(st==FALSE)GA_Error("GA (c) destroy failed",g_a);
}

void GA_Set_memory_limit(size_t limit)
{
Integer lim = (Integer)limit;
     ga_set_memory_limit_(&lim);
}

void GA_Zero(int g_a)
{
    Integer a=(Integer)g_a;
    ga_zero_(&a);
}

int GA_Pgroup_get_default()
{
    int value = (int)ga_pgroup_get_default_();
    return value;
}

void GA_Pgroup_set_default(int p_handle)
{
    Integer grp = (Integer)p_handle;
    ga_pgroup_set_default_(&grp);
}

int GA_Pgroup_get_mirror()
{
    int value = (int)ga_pgroup_get_mirror_();
    return value;
}

int GA_Pgroup_get_world()
{
    int value = (int)ga_pgroup_get_world_();
    return value;
}

int GA_Idot(int g_a, int g_b)
{
    int value;
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    gai_dot(C_INT, &a, &b, &value);
    return value;
}


long GA_Ldot(int g_a, int g_b)
{
    long value;
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    gai_dot(C_LONG, &a, &b, &value);
    return value;
}

long GA_Lldot(int g_a, int g_b)
{
    long long value;
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    gai_dot(C_LONGLONG, &a, &b, &value);
    return value;
}

     
double GA_Ddot(int g_a, int g_b)
{
    double value;
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    gai_dot(C_DBL, &a, &b, &value);
    return value;
}


DoubleComplex GA_Zdot(int g_a, int g_b)
{
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    return ga_zdot(&a,&b);
}

SingleComplex GA_Cdot(int g_a, int g_b)
{
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    return ga_cdot(&a,&b);
}

float GA_Fdot(int g_a, int g_b)
{
    float sum;
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    gai_dot(C_FLOAT, &a, &b, &sum);
    return sum;
}    

void GA_Fill(int g_a, void *value)
{
    Integer a=(Integer)g_a;
    ga_fill_(&a, value);
}


void GA_Scale(int g_a, void *value)
{
    Integer a=(Integer)g_a;
    ga_scale_(&a,value);
}


void GA_Add(void *alpha, int g_a, void* beta, int g_b, int g_c)
{
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    Integer c=(Integer)g_c;
    ga_add_(alpha, &a, beta, &b, &c);
}


void GA_Copy(int g_a, int g_b)
{
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    ga_copy_(&a, &b);
}


void NGA_Get(int g_a, int lo[], int hi[], void* buf, int ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_get_common(&a, _ga_lo, _ga_hi, buf, _ga_work,NULL);
}

void NGA_Get64(int g_a, int64_t lo[], int64_t hi[], void* buf, int64_t ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_get_common(&a, _ga_lo, _ga_hi, buf, _ga_work,NULL);
}

void NGA_NbGet(int g_a, int lo[], int hi[], void* buf, int ld[],
               ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_get_common(&a, _ga_lo, _ga_hi, buf, _ga_work,(Integer *)nbhandle);
}

void NGA_NbGet64(int g_a, int64_t lo[], int64_t hi[], void* buf, int64_t ld[],
               ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_get_common(&a, _ga_lo, _ga_hi, buf, _ga_work,(Integer *)nbhandle);
}

void NGA_Put(int g_a, int lo[], int hi[], void* buf, int ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_put_common(&a, _ga_lo, _ga_hi, buf, _ga_work,(Integer *)NULL);
}    

void NGA_Put64(int g_a, int64_t lo[], int64_t hi[], void* buf, int64_t ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_put_common(&a, _ga_lo, _ga_hi, buf, _ga_work,(Integer *)NULL);
}    

void NGA_NbPut(int g_a, int lo[], int hi[], void* buf, int ld[],
               ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_put_common(&a, _ga_lo, _ga_hi, buf, _ga_work,(Integer *)nbhandle);
}

void NGA_NbPut64(int g_a, int64_t lo[], int64_t hi[], void* buf, int64_t ld[],
                 ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_put_common(&a, _ga_lo, _ga_hi, buf, _ga_work,(Integer *)nbhandle);
}

int NGA_NbTest(ga_nbhdl_t* nbhandle)
{
    return(nga_test_internal((Integer *)nbhandle));
}

int NGA_NbWait(ga_nbhdl_t* nbhandle)
{
    return(nga_wait_internal((Integer *)nbhandle));
}

void NGA_Strided_put(int g_a, int lo[], int hi[], int skip[],
                     void* buf, int ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    COPYC2F(skip, _ga_skip, ndim);
    nga_strided_put_(&a, _ga_lo, _ga_hi, _ga_skip, buf, _ga_work);
}    

void NGA_Strided_put64(int g_a, int64_t lo[], int64_t hi[], int64_t skip[],
                     void* buf, int64_t ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    COPYC2F(skip, _ga_skip, ndim);
    nga_strided_put_(&a, _ga_lo, _ga_hi, _ga_skip, buf, _ga_work);
}

void NGA_Acc(int g_a, int lo[], int hi[], void* buf,int ld[], void* alpha)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_acc_(&a, _ga_lo, _ga_hi, buf, _ga_work, alpha);
}    

void NGA_Acc64(int g_a, int64_t lo[], int64_t hi[], void* buf, int64_t ld[], void* alpha)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_acc_(&a, _ga_lo, _ga_hi, buf, _ga_work, alpha);
}    

void NGA_NbAcc(int g_a, int lo[], int hi[], void* buf,int ld[], void* alpha,
               ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_acc_common(&a, _ga_lo,_ga_hi,buf,_ga_work,alpha,(Integer *)nbhandle);
}

void NGA_NbAcc64(int g_a, int64_t lo[], int64_t hi[], void* buf,int64_t ld[], void* alpha,
               ga_nbhdl_t* nbhandle)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    nga_acc_common(&a, _ga_lo,_ga_hi,buf,_ga_work,alpha,(Integer *)nbhandle);
}

void NGA_Periodic_get(int g_a, int lo[], int hi[], void* buf, int ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    ngai_periodic_(&a, _ga_lo, _ga_hi, buf, _ga_work, NULL, PERIODIC_GET);
}

void NGA_Periodic_get64(int g_a, int64_t lo[], int64_t hi[], void* buf, int64_t ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    ngai_periodic_(&a, _ga_lo, _ga_hi, buf, _ga_work, NULL, PERIODIC_GET);
}

void NGA_Periodic_put(int g_a, int lo[], int hi[], void* buf, int ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    ngai_periodic_(&a, _ga_lo, _ga_hi, buf, _ga_work, NULL, PERIODIC_PUT);
}    

void NGA_Periodic_put64(int g_a, int64_t lo[], int64_t hi[], void* buf, int64_t ld[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    ngai_periodic_(&a, _ga_lo, _ga_hi, buf, _ga_work, NULL, PERIODIC_PUT);
}

void NGA_Periodic_acc(int g_a, int lo[], int hi[], void* buf,int ld[], void* alpha)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    ngai_periodic_(&a, _ga_lo, _ga_hi, buf, _ga_work, alpha, PERIODIC_ACC);
}

void NGA_Periodic_acc64(int g_a, int64_t lo[], int64_t hi[], void* buf,int64_t ld[], void* alpha)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    COPYC2F(ld,_ga_work, ndim-1);
    ngai_periodic_(&a, _ga_lo, _ga_hi, buf, _ga_work, alpha, PERIODIC_ACC);
}

long NGA_Read_inc(int g_a, int subscript[], long inc)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    Integer in=(Integer)inc;
    COPYINDEX_C2F(subscript, _ga_lo, ndim);
    return (long)nga_read_inc_(&a, _ga_lo, &in);
}

long NGA_Read_inc64(int g_a, int64_t subscript[], long inc)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    Integer in=(Integer)inc;
    COPYINDEX_C2F(subscript, _ga_lo, ndim);
    return (long)nga_read_inc_(&a, _ga_lo, &in);
}

void NGA_Distribution(int g_a, int iproc, int lo[], int hi[])
{
     Integer a=(Integer)g_a;
     Integer p=(Integer)iproc;
     Integer ndim = ga_ndim_(&a);
     nga_distribution_(&a, &p, _ga_lo, _ga_hi);
     COPYINDEX_F2C(_ga_lo,lo, ndim);
     COPYINDEX_F2C(_ga_hi,hi, ndim);
}

void NGA_Distribution64(int g_a, int iproc, int64_t lo[], int64_t hi[])
{
     Integer a=(Integer)g_a;
     Integer p=(Integer)iproc;
     Integer ndim = ga_ndim_(&a);
     nga_distribution_(&a, &p, _ga_lo, _ga_hi);
     COPYINDEX_F2C_64(_ga_lo,lo, ndim);
     COPYINDEX_F2C_64(_ga_hi,hi, ndim);
}

void NGA_Select_elem(int g_a, char* op, void* val, int* index)
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     nga_select_elem_(&a, op, val, _ga_lo);
     COPYINDEX_F2C(_ga_lo,index,ndim);
}

void NGA_Select_elem64(int g_a, char* op, void* val, int64_t* index)
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     nga_select_elem_(&a, op, val, _ga_lo);
     COPYINDEX_F2C_64(_ga_lo,index,ndim);
}

int GA_Compare_distr(int g_a, int g_b)
{
    logical st;
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    st = ga_compare_distr_(&a,&b);
    if(st == TRUE) return 0;
    else return 1;
}

void NGA_Access(int g_a, int lo[], int hi[], void *ptr, int ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     COPYINDEX_C2F(lo,_ga_lo,ndim);
     COPYINDEX_C2F(hi,_ga_hi,ndim);

     nga_access_ptr(&a,_ga_lo, _ga_hi, ptr, _ga_work);
     COPYF2C(_ga_work,ld, ndim-1);
}

void NGA_Access64(int g_a, int64_t lo[], int64_t hi[], void *ptr, int64_t ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     COPYINDEX_C2F(lo,_ga_lo,ndim);
     COPYINDEX_C2F(hi,_ga_hi,ndim);

     nga_access_ptr(&a,_ga_lo, _ga_hi, ptr, _ga_work);
     COPYF2C_64(_ga_work,ld, ndim-1);
}

void NGA_Access_block(int g_a, int idx, void *ptr, int ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     Integer iblock = (Integer)idx;
     nga_access_block_ptr(&a,&iblock,ptr,_ga_work);
     COPYF2C(_ga_work,ld, ndim-1);
}

void NGA_Access_block_grid(int g_a, int index[], void *ptr, int ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     COPYF2C(_ga_lo,index, ndim);
     nga_access_block_grid_ptr(&a,_ga_lo,ptr,_ga_work);
     COPYF2C(_ga_work,ld, ndim-1);
}

void NGA_Access_block_segment(int g_a, int proc, void *ptr, int *len)
{
     Integer a=(Integer)g_a;
     Integer iblock = (Integer)proc;
     Integer ilen = (Integer)len;
     nga_access_block_segment_ptr(&a,&iblock,ptr,&ilen);
     *len = (int)ilen;
}

void NGA_Access_ghosts(int g_a, int dims[], void *ptr, int ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);

     nga_access_ghost_ptr(&a, _ga_lo, ptr, _ga_work);
     COPYF2C(_ga_work,ld, ndim-1);
     COPYF2C(_ga_lo, dims, ndim);
}

void NGA_Access_ghosts64(int g_a, int64_t dims[], void *ptr, int64_t ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);

     nga_access_ghost_ptr(&a, _ga_lo, ptr, _ga_work);
     COPYF2C_64(_ga_work,ld, ndim-1);
     COPYF2C_64(_ga_lo, dims, ndim);
}

void NGA_Access_ghost_element(int g_a, void *ptr, int subscript[], int ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     Integer _subscript[MAXDIM];
     Integer _ld[MAXDIM];

     COPYINDEX_C2F(subscript, _subscript, ndim);
     COPYINDEX_C2F(ld, _ld, ndim-1);
     nga_access_ghost_element_(&a, ptr, _subscript, _ld);
}

void NGA_Access_ghost_element64(int g_a, void *ptr, int64_t subscript[], int64_t ld[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     Integer _subscript[MAXDIM];
     Integer _ld[MAXDIM];

     COPYINDEX_C2F(subscript, _subscript, ndim);
     COPYINDEX_C2F(ld, _ld, ndim-1);
     nga_access_ghost_element_(&a, ptr, _subscript, _ld);
}

void NGA_Release(int g_a, int lo[], int hi[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     COPYINDEX_C2F(lo,_ga_lo,ndim);
     COPYINDEX_C2F(hi,_ga_hi,ndim);

     nga_release_(&a,_ga_lo, _ga_hi);
}

void NGA_Release64(int g_a, int64_t lo[], int64_t hi[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     COPYINDEX_C2F(lo,_ga_lo,ndim);
     COPYINDEX_C2F(hi,_ga_hi,ndim);

     nga_release_(&a,_ga_lo, _ga_hi);
}

void NGA_Release_block(int g_a, int idx)
{
     Integer a=(Integer)g_a;
     Integer iblock = (Integer)idx;

     nga_release_block_(&a, &iblock);
}

void NGA_Release_block_grid(int g_a, int index[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     COPYINDEX_C2F(index,_ga_lo,ndim);

     nga_release_block_(&a, _ga_lo);
}

void NGA_Release_block_segment(int g_a, int idx)
{
     Integer a=(Integer)g_a;
     Integer iproc = (Integer)idx;

     nga_release_block_segment_(&a, &iproc);
}

int NGA_Locate(int g_a, int subscript[])
{
    logical st;
    Integer a=(Integer)g_a, owner;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(subscript,_ga_lo,ndim);

    st = nga_locate_(&a,_ga_lo,&owner);
    if(st == TRUE) return (int)owner;
    else return -1;
}

int NGA_Locate64(int g_a, int64_t subscript[])
{
    logical st;
    Integer a=(Integer)g_a, owner;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(subscript,_ga_lo,ndim);

    st = nga_locate_(&a,_ga_lo,&owner);
    if(st == TRUE) return (int)owner;
    else return -1;
}

int NGA_Locate_region(int g_a,int lo[],int hi[],int map[],int procs[])
{
     logical st;
     Integer a=(Integer)g_a, np;
     Integer ndim = ga_ndim_(&a);
     Integer *tmap;
     int i;
     tmap = (Integer *)malloc( (int)(GA_Nnodes()*2*ndim *sizeof(Integer)));
     if(!map)GA_Error("NGA_Locate_region: unable to allocate memory",g_a);
     COPYINDEX_C2F(lo,_ga_lo,ndim);
     COPYINDEX_C2F(hi,_ga_hi,ndim);

     st = nga_locate_region_(&a,_ga_lo, _ga_hi, tmap, _ga_map_capi, &np);
     if(st==FALSE){
       free(tmap);
       return 0;
     }

     COPY(int,_ga_map_capi,procs, np);

        /* might have to swap lo/hi when copying */

     for(i=0; i< np*2; i++){
        Integer *ptmap = tmap+i*ndim;
        int *pmap = map +i*ndim;
        COPYINDEX_F2C(ptmap, pmap, ndim);  
     }
     free(tmap);
     return (int)np;
}

int NGA_Locate_region64(int g_a,int64_t lo[],int64_t hi[],int64_t map[],int procs[])
{
     logical st;
     Integer a=(Integer)g_a, np;
     Integer ndim = ga_ndim_(&a);
     Integer *tmap;
     int i;
     tmap = (Integer *)malloc( (int)(GA_Nnodes()*2*ndim *sizeof(Integer)));
     if(!map)GA_Error("NGA_Locate_region: unable to allocate memory",g_a);
     COPYINDEX_C2F(lo,_ga_lo,ndim);
     COPYINDEX_C2F(hi,_ga_hi,ndim);

     st = nga_locate_region_(&a,_ga_lo, _ga_hi, tmap, _ga_map_capi, &np);
     if(st==FALSE){
       free(tmap);
       return 0;
     }

     COPY(int,_ga_map_capi,procs, np);

        /* might have to swap lo/hi when copying */

     for(i=0; i< np*2; i++){
        Integer *ptmap = tmap+i*ndim;
        int64_t *pmap = map +i*ndim;
        COPYINDEX_F2C_64(ptmap, pmap, ndim);  
     }
     free(tmap);
     return (int)np;
}

int NGA_Locate_num_blocks(int g_a, int *lo, int *hi)
{
  Integer ret;
  Integer a = (Integer)g_a;
  Integer ndim = ga_ndim_(&a);
  COPYINDEX_C2F(lo,_ga_lo,ndim);
  COPYINDEX_C2F(hi,_ga_hi,ndim);
  ret = nga_locate_num_blocks_(&a, _ga_lo, _ga_hi);
  return (int)ret;
}


void NGA_Inquire(int g_a, int *type, int *ndim, int dims[])
{
     Integer a=(Integer)g_a;
     Integer ttype, nndim;
     nga_inquire(&a,&ttype, &nndim, _ga_dims);
     COPYF2C(_ga_dims, dims,nndim);  
     *ndim = (int)nndim;
     *type = (int)ttype;
}

void NGA_Inquire64(int g_a, int *type, int *ndim, int64_t dims[])
{
     Integer a=(Integer)g_a;
     Integer ttype, nndim;
     nga_inquire(&a,&ttype, &nndim, _ga_dims);
     COPYF2C_64(_ga_dims, dims,nndim);  
     *ndim = (int)nndim;
     *type = (int)ttype;
}

char* GA_Inquire_name(int g_a)
{
     Integer a=(Integer)g_a;
     char *ptr;
     ga_inquire_name(&a, &ptr);
     return(ptr);
}

int GA_Memory_limited(void)
{
    if(ga_memory_limited_() ==TRUE) return 1;
    else return 0;
}

void NGA_Proc_topology(int g_a, int proc, int coord[])
{
     Integer a=(Integer)g_a;
     Integer p=(Integer)proc;
     Integer ndim = ga_ndim_(&a);
     nga_proc_topology_(&a, &p, _ga_work);
     COPY(int,_ga_work, coord,ndim);  
}

void GA_Topology(int g_a, int dims[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     ga_topology_(&a, _ga_work);
     COPY(int,_ga_work, dims ,ndim);  
}

void GA_Check_handle(int g_a, char* string)
{
     Integer a=(Integer)g_a;
     ga_check_handle(&a,string);
}

int GA_Create_mutexes(int number)
{
     Integer n = (Integer)number;
     if(ga_create_mutexes_(&n) == TRUE)return 1;
     else return 0;
}

int GA_Destroy_mutexes(void) {
  if(ga_destroy_mutexes_() == TRUE) return 1;
  else return 0;
}

void GA_Lock(int mutex)
{
     Integer m = (Integer)mutex;
     ga_lock_(&m);
}

void GA_Unlock(int mutex)
{
     Integer m = (Integer)mutex;
     ga_unlock_(&m);
}

void GA_Brdcst(void *buf, int lenbuf, int root)
{
  Integer type=GA_TYPE_BRD;
  Integer len = (Integer)lenbuf;
  Integer orig = (Integer)root;
  ga_msg_brdcst(type, buf, len, orig);
}
   
void GA_Pgroup_brdcst(int grp_id, void *buf, int lenbuf, int root)
{
    Integer type=GA_TYPE_BRD;
    Integer len = (Integer)lenbuf;
    Integer orig = (Integer)root;
    Integer grp = (Integer)grp_id;
    ga_pgroup_brdcst_(&grp, &type, buf, &len, &orig);
}

void GA_Pgroup_sync(int grp_id)
{
    Integer grp = (Integer)grp_id;
    ga_pgroup_sync_(&grp);
}

void GA_Dgop(double x[], int n, char *op)
{
  Integer type=GA_TYPE_GOP;
  Integer len = (Integer)n;
  ga_dgop(type, x, len, op);
}

void GA_Gop(int type, void *x, int n, char *op)
{
    Integer itype = (Integer)type; 
    Integer len = (Integer)n;
    ga_gop(itype, x, len, op);
}
  
void GA_Lgop(long x[], int n, char *op)
{
  Integer type=GA_TYPE_GOP;
  Integer len = (Integer)n;
  ga_lgop(type, x, len, op);
}
  
void GA_Igop(Integer x[], int n, char *op)
{
  Integer type=GA_TYPE_GOP;
  Integer len = (Integer)n;
  ga_igop(type, x, len, op);
}

void GA_Fgop(float x[], int n, char *op)
{
  Integer type=GA_TYPE_GOP;
  Integer len = (Integer)n;
  ga_fgop(type, x, len, op);
}       

void GA_Pgroup_dgop(int grp_id, double x[], int n, char *op)
{
    Integer type=GA_TYPE_GOP;
    Integer len = (Integer)n;
    Integer grp = (Integer)grp_id;
    ga_pgroup_dgop(grp, type, x, len, op);
}
 
void GA_Pgroup_lgop(int grp_id, long x[], int n, char *op)
{
    Integer type=GA_TYPE_GOP;
    Integer len = (Integer)n;
    Integer grp = (Integer)grp_id;
    ga_pgroup_lgop(grp, type, x, len, op);
}
 
void GA_Pgroup_igop(int grp_id, Integer x[], int n, char *op)
{
    Integer type=GA_TYPE_GOP;
    Integer len = (Integer)n;
    Integer grp = (Integer)grp_id;
    ga_pgroup_igop(grp, type, x, len, op);
}
 
void GA_Pgroup_fgop(int grp_id, float x[], int n, char *op)
{
    Integer type=GA_TYPE_GOP;
    Integer len = (Integer)n;
    Integer grp = (Integer)grp_id;
    ga_pgroup_fgop(grp, type, x, len, op);
}

/*********** to do *******/
/*
void GA_Print_patch(int g_a,int ilo,int ihi,int jlo,int jhi,int pretty)
void GA_Copy_patch(ta,int g_a, int ailo, int aihi, int ajlo, int ajhi,
                             int g_b, int bilo, int bihi, int bjlo,int bjhi)
*/
void NGA_Scatter(int g_a, void *v, int* subsArray[], int n)
{
    int idx, i;
    Integer a = (Integer)g_a;
    Integer nv = (Integer)n;
    Integer ndim = ga_ndim_(&a);
    Integer *_subs_array;
    _subs_array = (Integer *)malloc((int)ndim* n * sizeof(Integer));
    if(_subs_array == NULL) GA_Error("Memory allocation failed.", 0);
    for(idx=0; idx<n; idx++)
        for(i=0; i<ndim; i++)
            _subs_array[idx*ndim+i] = subsArray[idx][i] + 1;
    
    nga_scatter_(&a, v, _subs_array , &nv);
    
    free(_subs_array);
}

void NGA_Scatter64(int g_a, void *v, int64_t* subsArray[], int64_t n)
{
    int64_t idx;
    int i;
    Integer a = (Integer)g_a;
    Integer nv = (Integer)n;
    Integer ndim = ga_ndim_(&a);
    Integer *_subs_array;
    _subs_array = (Integer *)malloc((int)ndim* n * sizeof(Integer));
    if(_subs_array == NULL) GA_Error("Memory allocation failed.", 0);
    for(idx=0; idx<n; idx++)
        for(i=0; i<ndim; i++)
            _subs_array[idx*ndim+i] = subsArray[idx][i] + 1;
    
    nga_scatter_(&a, v, _subs_array , &nv);
    
    free(_subs_array);
}

void NGA_Scatter_acc(int g_a, void *v, int* subsArray[], int n, void *alpha)
{
    int idx, i;
    Integer a = (Integer)g_a;
    Integer nv = (Integer)n;
    Integer ndim = ga_ndim_(&a);
    Integer *_subs_array;
    _subs_array = (Integer *)malloc((int)ndim* n * sizeof(Integer));
    if(_subs_array == NULL) GA_Error("Memory allocation failed.", 0);
    for(idx=0; idx<n; idx++)
        for(i=0; i<ndim; i++)
            _subs_array[idx*ndim+i] = subsArray[idx][i] + 1;
    
    nga_scatter_acc_(&a, v, _subs_array , &nv, alpha);
    
    free(_subs_array);
}

void NGA_Scatter_acc64(int g_a, void *v, int64_t* subsArray[], int64_t n, void *alpha)
{
    int64_t idx;
    int i;
    Integer a = (Integer)g_a;
    Integer nv = (Integer)n;
    Integer ndim = ga_ndim_(&a);
    Integer *_subs_array;
    _subs_array = (Integer *)malloc((int)ndim* n * sizeof(Integer));
    if(_subs_array == NULL) GA_Error("Memory allocation failed.", 0);
    for(idx=0; idx<n; idx++)
        for(i=0; i<ndim; i++)
            _subs_array[idx*ndim+i] = subsArray[idx][i] + 1;
    
    nga_scatter_acc_(&a, v, _subs_array , &nv, alpha);
    
    free(_subs_array);
}

void NGA_Gather(int g_a, void *v, int* subsArray[], int n)
{
    int idx, i;
    Integer a = (Integer)g_a;
    Integer nv = (Integer)n;
    Integer ndim = ga_ndim_(&a);
    Integer *_subs_array;
    _subs_array = (Integer *)malloc((int)ndim* n * sizeof(Integer));
    if(_subs_array == NULL) GA_Error("Memory allocation failed.", 0);

    /* adjust the indices for fortran interface */
    for(idx=0; idx<n; idx++)
        for(i=0; i<ndim; i++)
            _subs_array[idx*ndim+i] = subsArray[idx][i] + 1;
    
    nga_gather_(&a, v, _subs_array , &nv);
    
    free(_subs_array);
}


void NGA_Gather64(int g_a, void *v, int64_t* subsArray[], int64_t n)
{
    int64_t idx;
    int i;
    Integer a = (Integer)g_a;
    Integer nv = (Integer)n;
    Integer ndim = ga_ndim_(&a);
    Integer *_subs_array;
    _subs_array = (Integer *)malloc((int)ndim* n * sizeof(Integer));
    if(_subs_array == NULL) GA_Error("Memory allocation failed.", 0);

    /* adjust the indices for fortran interface */
    for(idx=0; idx<n; idx++)
        for(i=0; i<ndim; i++)
            _subs_array[idx*ndim+i] = subsArray[idx][i] + 1;
    
    nga_gather_(&a, v, _subs_array , &nv);
    
    free(_subs_array);
}

void GA_Dgemm(char ta, char tb, int m, int n, int k,
              double alpha, int g_a, int g_b, double beta, int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (DoublePrecision *)&alpha,(DoublePrecision *)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

void GA_Zgemm(char ta, char tb, int m, int n, int k,
              DoubleComplex alpha, int g_a, int g_b, 
	      DoubleComplex beta, int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (DoublePrecision *)&alpha,(DoublePrecision *)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

void GA_Cgemm(char ta, char tb, int m, int n, int k,
              SingleComplex alpha, int g_a, int g_b, 
	      SingleComplex beta, int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (float *)&alpha,(float *)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

void GA_Sgemm(char ta, char tb, int m, int n, int k,
              float alpha, int g_a, int g_b, 
	      float beta,  int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (DoublePrecision*)&alpha, (DoublePrecision*)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

void GA_Dgemm64(char ta, char tb, int64_t m, int64_t n, int64_t k,
                double alpha, int g_a, int g_b, double beta, int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (DoublePrecision *)&alpha,(DoublePrecision *)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

void GA_Zgemm64(char ta, char tb, int64_t m, int64_t n, int64_t k,
                DoubleComplex alpha, int g_a, int g_b, 
                DoubleComplex beta, int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (DoublePrecision *)&alpha,(DoublePrecision *)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

void GA_Cgemm64(char ta, char tb, int64_t m, int64_t n, int64_t k,
                SingleComplex alpha, int g_a, int g_b, 
                SingleComplex beta, int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (float *)&alpha,(float *)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

void GA_Sgemm64(char ta, char tb, int64_t m, int64_t n, int64_t k,
                float alpha, int g_a, int g_b, 
                float beta,  int g_c )
{
  Integer G_a = g_a;
  Integer G_b = g_b;
  Integer G_c = g_c;

  Integer ailo = 1;
  Integer aihi = m;
  Integer ajlo = 1;
  Integer ajhi = k;
  
  Integer bilo = 1;
  Integer bihi = k;
  Integer bjlo = 1;
  Integer bjhi = n;
  
  Integer cilo = 1;
  Integer cihi = m;
  Integer cjlo = 1;
  Integer cjhi = n;
  
  ga_matmul(&ta, &tb, (DoublePrecision*)&alpha, (DoublePrecision*)&beta,
	    &G_a, &ailo, &aihi, &ajlo, &ajhi,
	    &G_b, &bilo, &bihi, &bjlo, &bjhi,
	    &G_c, &cilo, &cihi, &cjlo, &cjhi);
}

/* Patch related */

void NGA_Copy_patch(char trans, int g_a, int alo[], int ahi[],
                                int g_b, int blo[], int bhi[])
{
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    nga_copy_patch(&trans, &a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi);
}

void NGA_Copy_patch64(char trans, int g_a, int64_t alo[], int64_t ahi[],
                                  int g_b, int64_t blo[], int64_t bhi[])
{
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    nga_copy_patch(&trans, &a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi);
}

void GA_Matmul_patch(char transa, char transb, void* alpha, void *beta,
		     int g_a, int ailo, int aihi, int ajlo, int ajhi,
		     int g_b, int bilo, int bihi, int bjlo, int bjhi,
		     int g_c, int cilo, int cihi, int cjlo, int cjhi)

{
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    Integer c=(Integer)g_c;

    Integer ga_ailo=(Integer)(ailo+1);
    Integer ga_aihi=(Integer)(aihi+1);
    Integer ga_ajlo=(Integer)(ajlo+1); 
    Integer ga_ajhi=(Integer)(ajhi+1);  
    
    Integer ga_bilo=(Integer)(bilo+1);
    Integer ga_bihi=(Integer)(bihi+1);
    Integer ga_bjlo=(Integer)(bjlo+1); 
    Integer ga_bjhi=(Integer)(bjhi+1);  
    
    Integer ga_cilo=(Integer)(cilo+1);
    Integer ga_cihi=(Integer)(cihi+1);
    Integer ga_cjlo=(Integer)(cjlo+1); 
    Integer ga_cjhi=(Integer)(cjhi+1);  
   
    ga_matmul_patch(&transa, &transb, alpha, beta,
		    &a, &ga_ailo, &ga_aihi, &ga_ajlo, &ga_ajhi,
		    &b, &ga_bilo, &ga_bihi, &ga_bjlo, &ga_bjhi,
		    &c, &ga_cilo, &ga_cihi, &ga_cjlo, &ga_cjhi);
}

void GA_Matmul_patch64(char transa, char transb, void* alpha, void *beta,
                       int g_a, int64_t ailo, int64_t aihi, int64_t ajlo, int64_t ajhi,
                       int g_b, int64_t bilo, int64_t bihi, int64_t bjlo, int64_t bjhi,
                       int g_c, int64_t cilo, int64_t cihi, int64_t cjlo, int64_t cjhi)

{
    Integer a=(Integer)g_a;
    Integer b=(Integer)g_b;
    Integer c=(Integer)g_c;

    Integer ga_ailo=(Integer)(ailo+1);
    Integer ga_aihi=(Integer)(aihi+1);
    Integer ga_ajlo=(Integer)(ajlo+1); 
    Integer ga_ajhi=(Integer)(ajhi+1);  
    
    Integer ga_bilo=(Integer)(bilo+1);
    Integer ga_bihi=(Integer)(bihi+1);
    Integer ga_bjlo=(Integer)(bjlo+1); 
    Integer ga_bjhi=(Integer)(bjhi+1);  
    
    Integer ga_cilo=(Integer)(cilo+1);
    Integer ga_cihi=(Integer)(cihi+1);
    Integer ga_cjlo=(Integer)(cjlo+1); 
    Integer ga_cjhi=(Integer)(cjhi+1);  
   
    ga_matmul_patch(&transa, &transb, alpha, beta,
		    &a, &ga_ailo, &ga_aihi, &ga_ajlo, &ga_ajhi,
		    &b, &ga_bilo, &ga_bihi, &ga_bjlo, &ga_bjhi,
		    &c, &ga_cilo, &ga_cihi, &ga_cjlo, &ga_cjhi);
}

void NGA_Matmul_patch(char transa, char transb, void* alpha, void *beta,
		      int g_a, int alo[], int ahi[], 
		      int g_b, int blo[], int bhi[], 
		      int g_c, int clo[], int chi[]) 

{
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
    
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    Integer c=(Integer)g_c;
    Integer cndim = ga_ndim_(&c);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    
    nga_matmul_patch(&transa, &transb, alpha, beta,
		     &a, _ga_alo, _ga_ahi,
		     &b, _ga_blo, _ga_bhi,
		     &c, _ga_clo, _ga_chi);
}

void NGA_Matmul_patch64(char transa, char transb, void* alpha, void *beta,
                        int g_a, int64_t alo[], int64_t ahi[], 
                        int g_b, int64_t blo[], int64_t bhi[], 
                        int g_c, int64_t clo[], int64_t chi[]) 

{
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
    
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    Integer c=(Integer)g_c;
    Integer cndim = ga_ndim_(&c);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    
    nga_matmul_patch(&transa, &transb, alpha, beta,
		     &a, _ga_alo, _ga_ahi,
		     &b, _ga_blo, _ga_bhi,
		     &c, _ga_clo, _ga_chi);
}

int NGA_Idot_patch(int g_a, char t_a, int alo[], int ahi[],
                   int g_b, char t_b, int blo[], int bhi[])
{
    Integer res;
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    res = nga_idot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);

    return ((int) res);
}

double NGA_Ddot_patch(int g_a, char t_a, int alo[], int ahi[],
                   int g_b, char t_b, int blo[], int bhi[])
{
    DoublePrecision res;
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);

    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);

    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    res = nga_ddot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);

    return ((double)res);
}

DoubleComplex NGA_Zdot_patch(int g_a, char t_a, int alo[], int ahi[],
                             int g_b, char t_b, int blo[], int bhi[])
{
    DoubleComplex res;
    
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
    
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    
    res = nga_zdot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);
    
    return (res);
}

SingleComplex NGA_Cdot_patch(int g_a, char t_a, int alo[], int ahi[],
                             int g_b, char t_b, int blo[], int bhi[])
{
    SingleComplex res;
    
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
    
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    
    res = nga_cdot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);
    
    return (res);
}

float NGA_Fdot_patch(int g_a, char t_a, int alo[], int ahi[],
                   int g_b, char t_b, int blo[], int bhi[])
{
    float res;
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
 
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
 
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
 
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
 
    res = nga_fdot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);
 
    return (res);
}                                           

int NGA_Idot_patch64(int g_a, char t_a, int64_t alo[], int64_t ahi[],
                     int g_b, char t_b, int64_t blo[], int64_t bhi[])
{
    Integer res;
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    res = nga_idot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);

    return ((int) res);
}

double NGA_Ddot_patch64(int g_a, char t_a, int64_t alo[], int64_t ahi[],
                        int g_b, char t_b, int64_t blo[], int64_t bhi[])
{
    DoublePrecision res;
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);

    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);

    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    res = nga_ddot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);

    return ((double)res);
}

DoubleComplex NGA_Zdot_patch64(int g_a, char t_a, int64_t alo[], int64_t ahi[],
                               int g_b, char t_b, int64_t blo[], int64_t bhi[])
{
    DoubleComplex res;
    
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
    
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    
    res = nga_zdot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);
    
    return (res);
}

SingleComplex NGA_Cdot_patch64(int g_a, char t_a, int64_t alo[], int64_t ahi[],
                               int g_b, char t_b, int64_t blo[], int64_t bhi[])
{
    SingleComplex res;
    
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
    
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
    
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    
    res = nga_cdot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);
    
    return (res);
}

float NGA_Fdot_patch64(int g_a, char t_a, int64_t alo[], int64_t ahi[],
                       int g_b, char t_b, int64_t blo[], int64_t bhi[])
{
    float res;
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);
 
    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);
 
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
 
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
 
    res = nga_fdot_patch(&a, &t_a, _ga_alo, _ga_ahi,
                         &b, &t_b, _ga_blo, _ga_bhi);
 
    return (res);
}


void NGA_Fill_patch(int g_a, int lo[], int hi[], void *val)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);

    nga_fill_patch_(&a, _ga_lo, _ga_hi, val);
}

void NGA_Fill_patch64(int g_a, int64_t lo[], int64_t hi[], void *val)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);

    nga_fill_patch_(&a, _ga_lo, _ga_hi, val);
}

void NGA_Zero_patch(int g_a, int lo[], int hi[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);

    nga_zero_patch_(&a, _ga_lo, _ga_hi);
}

void NGA_Zero_patch64(int g_a, int64_t lo[], int64_t  hi[])
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);

    nga_zero_patch_(&a, _ga_lo, _ga_hi);
}

void NGA_Scale_patch(int g_a, int lo[], int hi[], void *alpha)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);

    nga_scale_patch_(&a, _ga_lo, _ga_hi, alpha);
}

void NGA_Scale_patch64(int g_a, int64_t lo[], int64_t hi[], void *alpha)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);

    nga_scale_patch_(&a, _ga_lo, _ga_hi, alpha);
}

void NGA_Add_patch(void * alpha, int g_a, int alo[], int ahi[],
                   void * beta,  int g_b, int blo[], int bhi[],
                   int g_c, int clo[], int chi[])
{
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);

    Integer c=(Integer)g_c;
    Integer cndim = ga_ndim_(&c);

    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);

    nga_add_patch_(alpha, &a, _ga_alo, _ga_ahi, beta, &b, _ga_blo, _ga_bhi,
                   &c, _ga_clo, _ga_chi);
}

void NGA_Add_patch64(void * alpha, int g_a, int64_t alo[], int64_t ahi[],
                     void * beta,  int g_b, int64_t blo[], int64_t bhi[],
                                   int g_c, int64_t clo[], int64_t chi[])
{
    Integer a=(Integer)g_a;
    Integer andim = ga_ndim_(&a);

    Integer b=(Integer)g_b;
    Integer bndim = ga_ndim_(&b);

    Integer c=(Integer)g_c;
    Integer cndim = ga_ndim_(&c);

    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);

    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);

    nga_add_patch_(alpha, &a, _ga_alo, _ga_ahi, beta, &b, _ga_blo, _ga_bhi,
                   &c, _ga_clo, _ga_chi);
}

void NGA_Print_patch(int g_a, int lo[], int hi[], int pretty)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    Integer p = (Integer)pretty;
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
  
    nga_print_patch_(&a, _ga_lo, _ga_hi, &p);
}

void NGA_Print_patch64(int g_a, int64_t lo[], int64_t hi[], int pretty)
{
    Integer a=(Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    Integer p = (Integer)pretty;
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
  
    nga_print_patch_(&a, _ga_lo, _ga_hi, &p);
}

void GA_Print(int g_a)
{
    Integer a=(Integer)g_a;
    ga_print_(&a);
}

void GA_Print_file(FILE *file, int g_a)
{
  Integer G_a = g_a;
  ga_print_file(file, &G_a);
}

void GA_Diag_seq(int g_a, int g_s, int g_v, void *eval)
{
    Integer a = (Integer)g_a;
    Integer s = (Integer)g_s;
    Integer v = (Integer)g_v;

    ga_diag_seq_(&a, &s, &v, eval);
}

void GA_Diag_std_seq(int g_a, int g_v, void *eval)
{
    Integer a = (Integer)g_a;
    Integer v = (Integer)g_v;

    ga_diag_std_seq_(&a, &v, eval);
}

void GA_Diag(int g_a, int g_s, int g_v, void *eval)
{
    Integer a = (Integer)g_a;
    Integer s = (Integer)g_s;
    Integer v = (Integer)g_v;

    ga_diag_(&a, &s, &v, eval);
}

void GA_Diag_std(int g_a, int g_v, void *eval)
{
    Integer a = (Integer)g_a;
    Integer v = (Integer)g_v;

    ga_diag_std_(&a, &v, eval);
}

void GA_Diag_reuse(int reuse, int g_a, int g_s, int g_v, void *eval)
{
    Integer r = (Integer)reuse;
    Integer a = (Integer)g_a;
    Integer s = (Integer)g_s;
    Integer v = (Integer)g_v;

    ga_diag_reuse_(&r, &a, &s, &v, eval);
}

void GA_Lu_solve(char tran, int g_a, int g_b)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;

    Integer t;

    if(tran == 't' || tran == 'T') t = 1;
    else t = 0;

    ga_lu_solve_alt_(&t, &a, &b);
}

int GA_Llt_solve(int g_a, int g_b)
{
    Integer res;
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;

    res = ga_llt_solve_(&a, &b);

    return((int)res);
}

int GA_Solve(int g_a, int g_b)
{
    Integer res;
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;

    res = ga_solve_(&a, &b);

    return((int)res);
}

int GA_Spd_invert(int g_a)
{
    Integer res;
    Integer a = (Integer)g_a;

    res = ga_spd_invert_(&a);

    return((int)res);
}

void GA_Summarize(int verbose)
{
    Integer v = (Integer)verbose;

    ga_summarize_(&v);
}

void GA_Symmetrize(int g_a)
{
    Integer a = (Integer)g_a;

    ga_symmetrize_(&a);
}

void GA_Transpose(int g_a, int g_b)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;

    ga_transpose_(&a, &b);
}


void GA_Print_distribution(int g_a)
{
extern void gai_print_distribution(int fstyle, Integer g_a);

#ifdef USE_FAPI
    gai_print_distribution(1,(Integer)g_a);
#else
    gai_print_distribution(0,(Integer)g_a);
#endif
}


void NGA_Release_update(int g_a, int lo[], int hi[])
{
  Integer a = (Integer)g_a;
  Integer ndim = ga_ndim_(&a);
  COPYINDEX_C2F(lo,_ga_lo,ndim);
  COPYINDEX_C2F(hi,_ga_hi,ndim);

  nga_release_update_(&a,_ga_lo, _ga_hi);
}

void NGA_Release_update64(int g_a, int64_t lo[], int64_t hi[])
{
  Integer a = (Integer)g_a;
  Integer ndim = ga_ndim_(&a);
  COPYINDEX_C2F(lo,_ga_lo,ndim);
  COPYINDEX_C2F(hi,_ga_hi,ndim);

  nga_release_update_(&a,_ga_lo, _ga_hi);
}

void NGA_Release_update_block(int g_a, int idx)
{
     Integer a=(Integer)g_a;
     Integer iblock = (Integer)idx;

     nga_release_update_block_(&a, &iblock);
}

void NGA_Release_update_block_grid(int g_a, int index[])
{
     Integer a=(Integer)g_a;
     Integer ndim = ga_ndim_(&a);
     COPYINDEX_C2F(index,_ga_lo,ndim);
     nga_release_update_block_grid_(&a, _ga_lo);
}

void NGA_Release_update_block_segment(int g_a, int idx)
{
     Integer a=(Integer)g_a;
     Integer iproc = (Integer)idx;

     nga_release_update_block_segment_(&a, &iproc);
}


int GA_Ndim(int g_a)
{
    Integer a = (Integer)g_a;
    return (int)ga_ndim_(&a);
}


/*Limin's functions */


void GA_Step_bound_info(int g_xx, int g_vv, int g_xxll, int g_xxuu,  void *boundmin, void *wolfemin, void *boundmax)
{
    Integer xx = (Integer)g_xx;
    Integer vv = (Integer)g_vv;
    Integer xxll = (Integer)g_xxll;
    Integer xxuu = (Integer)g_xxuu;
    ga_step_bound_info_(&xx, &vv, &xxll, &xxuu, boundmin, wolfemin, boundmax);
}

void GA_Step_bound_info_patch(int g_xx, int xxlo[], int xxhi[],  int g_vv, int vvlo[], int vvhi[], int g_xxll, int xxlllo[], int xxllhi[], int g_xxuu,  int xxuulo[], int xxuuhi[], void *boundmin, void *wolfemin, void *boundmax)
{
    Integer xx = (Integer)g_xx;
    Integer vv = (Integer)g_vv;
    Integer xxll = (Integer)g_xxll;
    Integer xxuu = (Integer)g_xxuu;
    Integer ndim = ga_ndim_(&xx);
    COPYINDEX_C2F(xxlo,_ga_xxlo, ndim);
    COPYINDEX_C2F(xxhi,_ga_xxhi, ndim);
    COPYINDEX_C2F(vvlo,_ga_vvlo, ndim);
    COPYINDEX_C2F(vvhi,_ga_vvhi, ndim);
    COPYINDEX_C2F(xxlllo,_ga_xxlllo, ndim);
    COPYINDEX_C2F(xxllhi,_ga_xxllhi, ndim);
    COPYINDEX_C2F(xxuulo,_ga_xxuulo, ndim);
    COPYINDEX_C2F(xxuuhi,_ga_xxuuhi, ndim);
    ga_step_bound_info_patch_(&xx, _ga_xxlo, _ga_xxhi, &vv, _ga_vvlo, _ga_vvhi, &xxll, _ga_xxlllo, _ga_xxllhi, &xxuu, _ga_xxuulo, _ga_xxuuhi , 
    boundmin,wolfemin,boundmax);
}

void GA_Step_bound_info_patch64(int g_xx, int64_t xxlo[], int64_t xxhi[],
                                int g_vv, int64_t vvlo[], int64_t vvhi[],
                                int g_xxll, int64_t xxlllo[], int64_t xxllhi[],
                                int64_t g_xxuu,  int64_t xxuulo[], int64_t xxuuhi[],
                                void *boundmin, void *wolfemin, void *boundmax)
{
    Integer xx = (Integer)g_xx;
    Integer vv = (Integer)g_vv;
    Integer xxll = (Integer)g_xxll;
    Integer xxuu = (Integer)g_xxuu;
    Integer ndim = ga_ndim_(&xx);
    COPYINDEX_C2F(xxlo,_ga_xxlo, ndim);
    COPYINDEX_C2F(xxhi,_ga_xxhi, ndim);
    COPYINDEX_C2F(vvlo,_ga_vvlo, ndim);
    COPYINDEX_C2F(vvhi,_ga_vvhi, ndim);
    COPYINDEX_C2F(xxlllo,_ga_xxlllo, ndim);
    COPYINDEX_C2F(xxllhi,_ga_xxllhi, ndim);
    COPYINDEX_C2F(xxuulo,_ga_xxuulo, ndim);
    COPYINDEX_C2F(xxuuhi,_ga_xxuuhi, ndim);
    ga_step_bound_info_patch_(&xx, _ga_xxlo, _ga_xxhi, &vv, _ga_vvlo, _ga_vvhi, &xxll, _ga_xxlllo, _ga_xxllhi, &xxuu, _ga_xxuulo, _ga_xxuuhi , 
    boundmin,wolfemin,boundmax);
}

void GA_Step_max(int g_a, int g_b, void *step)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    ga_step_max_(&a, &b, step);
}

void GA_Step_max_patch(int g_a, int alo[], int ahi[], int g_b, int blo[], int bhi[], void *step)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(alo,_ga_alo, ndim);
    COPYINDEX_C2F(ahi,_ga_ahi, ndim);
    COPYINDEX_C2F(blo,_ga_blo, ndim);
    COPYINDEX_C2F(bhi,_ga_bhi, ndim);
    ga_step_max_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, step);
}

void GA_Step_max_patch64(int g_a, int64_t alo[], int64_t  ahi[],
                         int g_b, int64_t blo[], int64_t  bhi[], void *step)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(alo,_ga_alo, ndim);
    COPYINDEX_C2F(ahi,_ga_ahi, ndim);
    COPYINDEX_C2F(blo,_ga_blo, ndim);
    COPYINDEX_C2F(bhi,_ga_bhi, ndim);
    ga_step_max_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, step);
}

void GA_Abs_value(int g_a)
{
    Integer a = (Integer)g_a;
    ga_abs_value_(&a);
}

void GA_Add_constant(int g_a, void *alpha)
{
    Integer a = (Integer)g_a;
    ga_add_constant_(&a, alpha);
}


void GA_Recip(int g_a)
{
    Integer a = (Integer)g_a;
    ga_recip_(&a);
}

void GA_Elem_multiply(int g_a, int g_b, int g_c)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    ga_elem_multiply_(&a, &b, &c);
}

void GA_Elem_divide(int g_a, int g_b, int g_c)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    ga_elem_divide_(&a, &b, &c);
}

void GA_Elem_maximum(int g_a, int g_b, int g_c)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    ga_elem_maximum_(&a, &b, &c);
}


void GA_Elem_minimum(int g_a, int g_b, int g_c)
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    ga_elem_minimum_(&a, &b, &c);
}


void GA_Abs_value_patch(int g_a, int *lo, int *hi)
{
    Integer a = (Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    ga_abs_value_patch_(&a,_ga_lo, _ga_hi);
}

void GA_Abs_value_patch64(int g_a, int64_t *lo, int64_t *hi)
{
    Integer a = (Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    ga_abs_value_patch_(&a,_ga_lo, _ga_hi);
}

void GA_Add_constant_patch(int g_a, int *lo, int* hi, void *alpha)
{
    Integer a = (Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    ga_add_constant_patch_(&a, _ga_lo, _ga_hi, alpha);
}

void GA_Add_constant_patch64(int g_a, int64_t *lo, int64_t *hi, void *alpha)
{
    Integer a = (Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    ga_add_constant_patch_(&a, _ga_lo, _ga_hi, alpha);
}

void GA_Recip_patch(int g_a, int *lo, int *hi)
{
    Integer a = (Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    ga_recip_patch_(&a,_ga_lo, _ga_hi);
}

void GA_Recip_patch64(int g_a, int64_t *lo,  int64_t *hi)
{
    Integer a = (Integer)g_a;
    Integer ndim = ga_ndim_(&a);
    COPYINDEX_C2F(lo,_ga_lo, ndim);
    COPYINDEX_C2F(hi,_ga_hi, ndim);
    ga_recip_patch_(&a,_ga_lo, _ga_hi);
}

void GA_Elem_multiply_patch(int g_a, int alo[], int ahi[],
                            int g_b, int blo[], int bhi[],
                            int g_c, int clo[], int chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_multiply_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}

void GA_Elem_multiply_patch64(int g_a, int64_t alo[], int64_t ahi[],
                              int g_b, int64_t blo[], int64_t bhi[],
                              int g_c, int64_t clo[], int64_t chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_multiply_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}

void GA_Elem_divide_patch(int g_a, int alo[], int ahi[],
                          int g_b, int blo[], int bhi[],
                          int g_c, int clo[], int chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_divide_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}

void GA_Elem_divide_patch64(int g_a, int64_t alo[], int64_t ahi[],
                            int g_b, int64_t blo[], int64_t bhi[],
                            int g_c, int64_t clo[], int64_t chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_divide_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}


void GA_Elem_maximum_patch(int g_a, int alo[], int ahi[],
                           int g_b, int blo[], int bhi[],
                           int g_c, int clo[], int chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_maximum_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}

void GA_Elem_maximum_patch64(int g_a, int64_t alo[], int64_t ahi[],
                             int g_b, int64_t blo[], int64_t bhi[],
                             int g_c, int64_t clo[], int64_t chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_maximum_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}

void GA_Elem_minimum_patch(int g_a, int alo[], int ahi[],
                           int g_b, int blo[], int bhi[],
                           int g_c, int clo[], int chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_minimum_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}

void GA_Elem_minimum_patch64(int g_a, int64_t alo[], int64_t ahi[],
                             int g_b, int64_t blo[], int64_t bhi[],
                             int g_c, int64_t clo[], int64_t chi[])
{
    Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    ga_elem_minimum_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi);
}

void GA_Shift_diagonal(int g_a, void *c){
 Integer a = (Integer )g_a;
 ga_shift_diagonal_(&a, c);
}

void GA_Set_diagonal(int g_a, int g_v){
 Integer a = (Integer )g_a;
 Integer v = (Integer )g_v;
 ga_set_diagonal_(&a, &v);
}

void GA_Zero_diagonal(int g_a){
 Integer a = (Integer )g_a;
 ga_zero_diagonal_(&a);
}
void GA_Add_diagonal(int g_a, int g_v){
 Integer a = (Integer )g_a;
 Integer v = (Integer )g_v;
 ga_add_diagonal_(&a, &v);
}

void GA_Get_diag(int g_a, int g_v){
 Integer a = (Integer )g_a;
 Integer v = (Integer )g_v;
 ga_get_diag_(&a, &v);
}

void GA_Scale_rows(int g_a, int g_v){
 Integer a = (Integer )g_a;
 Integer v = (Integer )g_v;
 ga_scale_rows_(&a, &v);
}

void GA_Scale_cols(int g_a, int g_v){
 Integer a = (Integer )g_a;
 Integer v = (Integer )g_v;
 ga_scale_cols_(&a, &v);
}
void GA_Norm1(int g_a, double *nm){
 Integer a = (Integer )g_a;
 ga_norm1_(&a, nm);
}

void GA_Norm_infinity(int g_a, double *nm){
 Integer a = (Integer )g_a;
 ga_norm_infinity_(&a, nm);
}


void GA_Median(int g_a, int g_b, int g_c, int g_m){
 Integer a = (Integer )g_a;
 Integer b = (Integer )g_b;
 Integer c= (Integer )g_c;
 Integer m = (Integer )g_m;
 ga_median_(&a, &b, &c, &m);
}

void GA_Median_patch(int g_a, int *alo, int *ahi,
                     int g_b, int *blo, int *bhi,
                     int g_c, int *clo, int *chi,
                     int g_m, int *mlo, int *mhi){

   Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer m = (Integer )g_m;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    Integer mndim = ga_ndim_(&m);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    COPYINDEX_C2F(mlo,_ga_mlo, mndim);
    COPYINDEX_C2F(mhi,_ga_mhi, mndim);
    ga_median_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi, &m, _ga_mlo, _ga_mhi);
}

void GA_Median_patch64(int g_a, int64_t *alo, int64_t *ahi,
                       int g_b, int64_t *blo, int64_t *bhi,
                       int g_c, int64_t *clo, int64_t *chi,
                       int g_m, int64_t *mlo, int64_t *mhi){

   Integer a = (Integer)g_a;
    Integer b = (Integer)g_b;
    Integer c = (Integer)g_c;
    Integer m = (Integer )g_m;
    Integer andim = ga_ndim_(&a);
    Integer bndim = ga_ndim_(&b);
    Integer cndim = ga_ndim_(&c);
    Integer mndim = ga_ndim_(&m);
    COPYINDEX_C2F(alo,_ga_alo, andim);
    COPYINDEX_C2F(ahi,_ga_ahi, andim);
    COPYINDEX_C2F(blo,_ga_blo, bndim);
    COPYINDEX_C2F(bhi,_ga_bhi, bndim);
    COPYINDEX_C2F(clo,_ga_clo, cndim);
    COPYINDEX_C2F(chi,_ga_chi, cndim);
    COPYINDEX_C2F(mlo,_ga_mlo, mndim);
    COPYINDEX_C2F(mhi,_ga_mhi, mndim);
    ga_median_patch_(&a, _ga_alo, _ga_ahi, &b, _ga_blo, _ga_bhi, &c, _ga_clo, _ga_chi, &m, _ga_mlo, _ga_mhi);
}

#ifdef WIN32
#include <armci.h>
#else
#include <../../armci/src/armci.h>
#endif

/* return number of nodes being used in a cluster */
int GA_Cluster_nnodes()
{
    return armci_domain_count(ARMCI_DOMAIN_SMP);
} 

/* returns ClusterNode id of the calling process */
int GA_Cluster_nodeid() 
{
    return armci_domain_my_id(ARMCI_DOMAIN_SMP);
}

/* returns ClusterNode id of the specified process */
int GA_Cluster_proc_nodeid(int proc)
{
    return armci_domain_id(ARMCI_DOMAIN_SMP, proc);
}

/* return number of processes being used on the specified node */
int GA_Cluster_nprocs(int x) 
{
    return armci_domain_nprocs(ARMCI_DOMAIN_SMP,x);
}

/* global id of the calling process */
int GA_Cluster_procid(int node, int loc_proc)
{
    return armci_domain_glob_proc_id(ARMCI_DOMAIN_SMP,
                                     node, loc_proc);
}

double GA_Wtime()
{
    return (double)ga_wtime_();
}

void GA_Set_debug(int flag)
{
    Integer aa;
    aa = (Integer)flag;
    ga_set_debug_(&aa);
}

int GA_Get_debug()
{
    return (int)ga_get_debug_();
}


#ifdef DO_CKPT
void GA_Checkpoint(int* gas, int num)
{
    ga_checkpoint_arrays_(gas,num);
}
#endif
