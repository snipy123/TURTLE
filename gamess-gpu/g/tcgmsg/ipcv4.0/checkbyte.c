/* $Header: /c/qcg/cvs/psh/GAMESS-UK/g/tcgmsg/ipcv4.0/checkbyte.c,v 1.1.1.5 2007-10-30 10:14:13 jmht Exp $ */

unsigned char CheckByte(c, n)
    unsigned char *c;
    long n;
{
/*
  unsigned char sum = (char) 0;
  while (n-- > 0)
    sum  = sum ^ *c++;

  return sum;
*/

  unsigned int sum = 0;
  unsigned int mask = 0xff;

  while (n-- > 0)
    sum += (int) *c++;

  sum = (sum + (sum>>8) + (sum>>16) + (sum>>24)) & mask;
  return (unsigned char) sum;
}
