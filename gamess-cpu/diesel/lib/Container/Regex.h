// This may look like C code, but it is really -*- C++ -*-
/* 
Copyright (C) 1988 Free Software Foundation
    written by Doug Lea (dl@rocky.oswego.edu)

This file is part of the GNU C++ Library.  This library is free
software; you can redistribute it and/or modify it under the terms of
the GNU Library General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your
option) any later version.  This library is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.  See the GNU Library General Public License for more details.
You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/


#ifndef _Regex_h
#define _Regex_h 1

#include "../../config.h"

#undef OK

#if defined(SHORT_NAMES) || defined(VMS)
#define re_compile_pattern	recmppat
#define re_pattern_buffer	repatbuf
#define re_registers		reregs
#endif

struct re_pattern_buffer;       // defined elsewhere
struct re_registers;

class Regex
{
public:

                     Regex(const Regex&) {}  // no X(X&)
  void               operator = (const Regex&) {} // no assignment

protected:
  re_pattern_buffer* buf;
  re_registers*      reg;

public:
                     Regex(const char* t, 
                           INT fast = 0, 
                           INT bufsize = 40, 
                           const char* transtable = 0);

                    ~Regex();

  INT                match(const char* s, INT len, INT pos = 0) const;
  INT                search(const char* s, INT len, 
                            INT& matchlen, INT startpos = 0) const;
  INT                match_info(INT& start, INT& length, INT nth = 0) const;

  INT                OK() const;  // representation invariant
};

// some built in regular expressions

extern const Regex RXwhite;          // = "[ \n\t\r\v\f]+"
extern const Regex RXint;            // = "-?[0-9]+"
extern const Regex RXdouble;         // = "-?\\(\\([0-9]+\\.[0-9]*\\)\\|
                                     //    \\([0-9]+\\)\\|\\(\\.[0-9]+\\)\\)
                                     //    \\([eE][---+]?[0-9]+\\)?"
extern const Regex RXalpha;          // = "[A-Za-z]+"
extern const Regex RXlowercase;      // = "[a-z]+"
extern const Regex RXuppercase;      // = "[A-Z]+"
extern const Regex RXalphanum;       // = "[0-9A-Za-z]+"
extern const Regex RXidentifier;     // = "[A-Za-z_][A-Za-z0-9_]*"


#endif
