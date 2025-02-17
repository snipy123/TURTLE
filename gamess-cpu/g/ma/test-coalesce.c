/*
 * $Id: test-coalesce.c,v 1.1.1.2 2002-12-23 14:11:31 psh Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include "macdecls.h"

#define MAXHANDLES 10

main()
{
    Integer     bytes_heap;
    Integer     bytes_stack;
    int         howmany;
    Boolean     ok;

    Integer     handle[MAXHANDLES];
    Integer     index[MAXHANDLES];

    /* set sizes of heap and stack */
    bytes_heap = 1024;
    bytes_stack = 0;

    /* initialize */
    ok = MA_init(MT_CHAR, bytes_stack, bytes_heap);
    if (!ok)
    {
        (void)fprintf(stderr, "MA_init failed; punting\n");
        exit(1);
    }

    howmany = MA_inquire_heap(MT_INT);
    (void)printf("MA_inquire_heap(MT_INT) = %d\n", howmany);

    printf("# Allocating 4 memory segments\n");
    MA_alloc_get(MT_INT, howmany/5, "heap0", &handle[0], &index[0]);
    MA_alloc_get(MT_INT, howmany/5, "heap1", &handle[1], &index[1]);
    MA_alloc_get(MT_INT, howmany/5, "heap2", &handle[2], &index[2]);
    MA_alloc_get(MT_INT, howmany/5, "heap3", &handle[3], &index[3]);

    printf("# Deleting 2 non-adjacent memory segments\n");
    MA_free_heap(handle[0]);
    MA_free_heap(handle[2]);

    printf("# Attempting to allocate memory segment -- should fail\n");
    MA_alloc_get(MT_INT, howmany/4, "heap4", &handle[4], &index[4]);

    printf("# Freeing some memory and trying again -- should succeed\n");
    MA_free_heap(handle[1]);
    MA_alloc_get(MT_INT, howmany/4, "heap4", &handle[4], &index[4]);

    printf("# Printing stats for allocated blocks -- should be two active\n");
    MA_summarize_allocated_blocks();
}
