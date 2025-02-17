/*
 * $Id: test-inquire.c,v 1.1.1.1 2002-12-23 14:11:31 psh Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include "macdecls.h"

#define MAXHANDLES 10

static void print_inquire();

main()
{
    Integer     units_heap;
    Integer     units_stack;
    int         howmany;
    Boolean     ok;

    Integer     handle[MAXHANDLES];
    Integer     index[MAXHANDLES];

    /* set sizes of heap and stack */
    units_heap = 50000;
    units_stack = 20000;

    /* initialize */
    ok = MA_init(MT_DBL, units_stack, units_heap);
    if (!ok)
    {
        (void)fprintf(stderr, "MA_init failed; punting\n");
        exit(1);
    }

    printf("# initialized heap = %d, stack = %d\n", units_heap, units_stack);

    printf("# should see roughly the following values:\n");
    printf("#  MA_inquire_heap(MT_DBL)               = 50K\n");
    printf("#  MA_inquire_heap_check_stack(MT_DBL)   = 50K\n");
    printf("#  MA_inquire_heap_no_partition(MT_DBL)  = 70K\n");
    printf("#  MA_inquire_stack(MT_DBL)              = 20K\n");
    printf("#  MA_inquire_stack_check_heap(MT_DBL)   = 20K\n");
    printf("#  MA_inquire_stack_no_partition(MT_DBL) = 70K\n");

    print_inquire();

    printf("# allocate 2 heap (10K, 20K), 1 stack (35K)\n");
    MA_alloc_get(MT_DBL, 10000, "heap0", &handle[0], &index[0]);
    MA_alloc_get(MT_DBL, 20000, "heap1", &handle[1], &index[1]);
    MA_push_get(MT_DBL, 35000, "stack0", &handle[2], &index[2]);

    printf("# free 1 heap (10K)\n");
    MA_free_heap(handle[0]);

    printf("# should see roughly the following values:\n");
    printf("#  MA_inquire_heap(MT_DBL)               = 20K\n");
    printf("#  MA_inquire_heap_check_stack(MT_DBL)   = 10K\n");
    printf("#  MA_inquire_heap_no_partition(MT_DBL)  = 10K\n");
    printf("#  MA_inquire_stack(MT_DBL)              = 0\n");
    printf("#  MA_inquire_stack_check_heap(MT_DBL)   = 0\n");
    printf("#  MA_inquire_stack_no_partition(MT_DBL) = 5K\n");

    print_inquire();
}

void print_inquire()
{
    int howmany;

    (void)printf("--------------------------------------------------------\n");

    howmany = MA_inquire_heap(MT_DBL);
    (void)printf("MA_inquire_heap(MT_DBL)               = %d\n", howmany);
    howmany = MA_inquire_heap_check_stack(MT_DBL);
    (void)printf("MA_inquire_heap_check_stack(MT_DBL)   = %d\n", howmany);
    howmany = MA_inquire_heap_no_partition(MT_DBL);
    (void)printf("MA_inquire_heap_no_partition(MT_DBL)  = %d\n", howmany);

    howmany = MA_inquire_stack(MT_DBL);
    (void)printf("MA_inquire_stack(MT_DBL)              = %d\n", howmany);
    howmany = MA_inquire_stack_check_heap(MT_DBL);
    (void)printf("MA_inquire_stack_check_heap(MT_DBL)   = %d\n", howmany);
    howmany = MA_inquire_stack_no_partition(MT_DBL);
    (void)printf("MA_inquire_stack_no_partition(MT_DBL) = %d\n", howmany);

    (void)printf("--------------------------------------------------------\n");
}
