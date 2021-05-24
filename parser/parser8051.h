/* Copyright (C) 2013, 2014, 2021 Luk Bettale

   This program is free software: you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, either version 3 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>. */

#ifndef PARSER8051_H
#define PARSER8051_H

#include <stdint.h>
#include <stdio.h>

#define line_print_error(s) fprintf (stderr, "line %u: %s\n", \
                                     1+parser8051->line_no, s)
#define line_printf_error(s, ...) fprintf (stderr, "line %u: " s "\n", \
                                           1+parser8051->line_no, __VA_ARGS__)

#ifdef DEBUG
#define line_print_info line_print_error
#define line_printf_info line_printf_error
#else
#define line_print_info(s) ;
#define line_printf_info(s, ...) ;
#endif

#define GET_COUNTER(x,seg) ((x)->counters[-(1+(seg))])
#define COUNTER(x) GET_COUNTER ((x),(x)->current_segment)

#define PARSER8051_MAX_LABEL_LENGTH 64
#define PARSER8051_MAX_SYMBOLS 65536
#define PARSER8051_MAX_LABELS 65536
#define PARSER8051_MAX_SEGMENTS 256

enum SEGMENT_8051
  {
    SEG_8051_NONE  = -1,
    SEG_8051_DATA  = -2,
    SEG_8051_XDATA = -3,
    SEG_8051_BIT   = -4,
    SEG_8051_CODE  = -5,
  };

enum TYPE_8051
  {
    TYPE_8051_NONE,
    TYPE_8051_DATA,
    TYPE_8051_XDATA,
    TYPE_8051_BIT,
    TYPE_8051_CODE,
    TYPE_8051_CONST
  };

struct parser8051_context
{
  unsigned int line_no;
  char symbols[PARSER8051_MAX_SYMBOLS][PARSER8051_MAX_LABEL_LENGTH];
  int32_t values[PARSER8051_MAX_SYMBOLS];
  enum TYPE_8051 types[PARSER8051_MAX_SYMBOLS];
  enum SEGMENT_8051 current_segment;
  int32_t counters[5];
};

/* defined by yacc */
extern FILE *yyin;
extern FILE *scan_yyin;
extern int scan_yyparse (void);
extern int yyparse (void);

/* global to be passed to lex and yacc */
extern struct parser8051_context *parser8051;

extern int parser8051_inst_process (struct parser8051_context *parser8051,
                                    unsigned int len, unsigned int opcode);

extern int parser8051_init_context (struct parser8051_context *parser8051);
extern void from_top (struct parser8051_context *parser8051);

#endif  /* PARSER8051_H */
