/* Copyright (C) 2013, 2014 Luk Bettale

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

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "parser8051.h"

extern FILE *yyin;
extern int scan_yyparse (void);
extern int yyparse (void);

/* global to be passed to lex and yacc */
struct parser8051_context *parser8051;

static const char *asm_symbols[] =
  {
    "AR0","AR1","AR2","AR3","AR4","AR5","AR6","AR7",
    "SP","DPL","DPH","PCON",
    "TCON","TMOD","TL0","TL1","TH0","TH1",
    "SCON","SBUF",
    "IE","IP",
    "P0","P1","P2","P3",
    "PSW","ACC","B",

    "TF1","TR1","TF0","TR0","IE1","IT1","IE0","IT0",
    "SM0","SM1","SM2","REN","TB8","RB8","TI","RI",
    "EA","ES","ET1","EX1","ET0","EX0",
    "PS","PT1","PX1","PT0","PX0",
    "CY","AC","F0","RS1","RS0","OV","P"
  };

static const uint8_t asm_values[] =
  {
    0,1,2,3,4,5,6,7,
    0x81,0x82,0x83,0x87,
    0x88,0x89,0x8A,0x8B,0x8C,0x8D,
    0x98,0x99,
    0xA8,0xB8,
    0x80,0x90,0xA0,0xB0,
    0xD0,0xE0,0xF0,

    0x8F,0x8E,0x8D,0x8C,0x8B,0x8A,0x89,0x88,
    0x9F,0x9E,0x9D,0x9C,0x9B,0x9A,0x99,0x98,
    0xAF,0xAC,0xAB,0xAA,0xA9,0xA8,
    0xBC,0xBB,0xBA,0xB9,0xB8,
    0xD7,0xD6,0xD5,0xD4,0xD3,0xD2,0xD0
  };

static void init_symbols (struct parser8051_context *parser8051)
{
  unsigned int n;
  for (n = 0; n < sizeof asm_values; n++)
    {
      strcpy (parser8051->symbols[n], asm_symbols[n]);
      parser8051->values[n] = asm_values[n];
    }
}

int parser8051_init_context (struct parser8051_context *parser8051)
{

  if (parser8051 != NULL)
    {
      int n;
      for (n = 0; n < PARSER8051_MAX_SYMBOLS; n++)
        memset (parser8051->symbols[n], 0, PARSER8051_MAX_LABEL_LENGTH);
      for (n = 0; n < PARSER8051_MAX_LABELS; n++)
        parser8051->values[n] = SEG_8051_NONE;

      from_top (parser8051);
      init_symbols (parser8051);
      return 0;
    }

  return 1;
}

void from_top (struct parser8051_context *parser8051)
{
  int n;
  for (n = 0; n < 8; n++)
    parser8051->values[n] = n;
  GET_COUNTER (parser8051, SEG_8051_NONE) = 0;
  GET_COUNTER (parser8051, SEG_8051_DATA) = 0x30;
  GET_COUNTER (parser8051, SEG_8051_XDATA) = 0;
  GET_COUNTER (parser8051, SEG_8051_BIT) = 0;
  GET_COUNTER (parser8051, SEG_8051_CODE) = 0;
  parser8051->line_no = 0;
  parser8051->current_segment = SEG_8051_CODE;
}
