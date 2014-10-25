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

%{
#include <stdint.h>
#include <stdio.h>

#include "parser8051.h"

int yyerror (char *s);

extern struct parser8051_context *parser8051;

extern int yylex (void);
%}

%token ENDL

 /* assembly mnemonics */
%token NOP

%token SJMP
%token AJMP
%token LJMP
%token JMP

%token ACALL
%token LCALL
%token CALL
%token RET
%token RETI

%token RR
%token RRC
%token RL
%token RLC
%token SWAP
%token DA
%token CLR
%token CPL
%token SETB

%token MOV
%token MOVX
%token MOVC
%token XCH
%token XCHD

%token ADD
%token ADDC
%token SUBB
%token XRL
%token ANL
%token ORL

%token MUL
%token DIV

%token JZ
%token JNZ
%token JC
%token JNC
%token JB
%token JNB
%token JBC

%token CJNE
%token DJNZ

%token PUSH
%token POP
%token INC
%token DEC

%token A C DPTR PC AB
%token REG

%token ID NUMBER

%token SEGMENT RSEG
%token AT
%token ORG
%token DSEG XSEG BSEG CSEG
%token DATA XDATA BIT CODE

%token DS DBIT DB

%token EQU SET

%token USING

%token END

 /* operators precedence */
%token LSH RSH
%token HIGH LOW

%left '.'
%left '|'
%left '^'
%left '&'
%left LSH RSH
%left '+' '-'
%left '*' '/'
%nonassoc UNARY

 /* starting state */
%start source

%%
source: program END ENDL
{ parser8051->line_no++; return 0; }
| program
;

symbols_decl:
ID SEGMENT DATA
| ID SEGMENT XDATA
| ID SEGMENT BIT
| ID SEGMENT CODE
| ID DATA value8
| ID XDATA value16
| ID BIT value8
| ID CODE value16
| ID EQU value
| ID SET value
{ parser8051->values[$1] = $3; }
| USING value
{
  int i;
  for (i = 0; i < 8; i++)
    parser8051->values[i] = ($2 << 3) + i;
}
;

segment_head:
RSEG ID
{
  parser8051->current_segment = parser8051->values[$2];
}
| DSEG
{
  parser8051->current_segment = SEG_8051_DATA;
}
| BSEG
{
  parser8051->current_segment = SEG_8051_BIT;
}
| XSEG
{
  parser8051->current_segment = SEG_8051_XDATA;
}
| CSEG
{
  parser8051->current_segment = SEG_8051_CODE;
}
| DSEG AT value
{
  parser8051->current_segment = SEG_8051_DATA;
  COUNTER (parser8051) = $3;
}
| BSEG AT value
{
  parser8051->current_segment = SEG_8051_BIT;
  COUNTER (parser8051) = $3;
}
| XSEG AT value
{
  parser8051->current_segment = SEG_8051_XDATA;
  COUNTER (parser8051) = $3;
}
| CSEG AT value
{
  parser8051->current_segment = SEG_8051_CODE;
  for (; COUNTER (parser8051) < $3; COUNTER (parser8051)++)
    parser8051_inst_process (parser8051, 1, 0x00);
}
| ORG value
{
  if (parser8051->current_segment == SEG_8051_CODE)
    {
      for (; COUNTER (parser8051) < $2; COUNTER (parser8051)++)
        parser8051_inst_process (parser8051, 1, 0x00);
    }
  COUNTER (parser8051) = $2;
}
;

line:
segment_head
| symbols_decl
| label
| label inst
{ COUNTER (parser8051) += $2; }
;


program:
program line ENDL
{ parser8051->line_no++; }
| /* empty program */
;

label:
ID ':'
{
  if (parser8051->values[$1] != COUNTER (parser8051))
    {
      if (parser8051->values[$1] < 0)
        line_printf_error ("undefined label: %s ",
                           parser8051->symbols[$1]);
      else
        line_printf_error ("multiply defined label: %s "
                           "(first occurence here)", parser8051->symbols[$1]);
      return -1;
    }
}
| /* no label */
;

value:
NUMBER
{ $$ = $1; }
| ID
{
  if (parser8051->values[$1] < 0)
    {
      line_printf_error ("undefined label: %s", parser8051->symbols[$1]);
      return -1;
    }
  $$ = parser8051->values[$1];
}
| '$'
{ $$ = COUNTER (parser8051); }
| value '|' value
{ $$ = $1 | $3; }
| value '^' value
{ $$ = $1 ^ $3; }
| value '&' value
{ $$ = $1 & $3; }
| value LSH value
{ $$ = $1 << $3; }
| value RSH value
{ $$ = $1 >> $3; }
| value '+' value
{ $$ = $1 + $3; }
| value '-' value
{ $$ = $1 - $3; }
| value '*' value
{ $$ = $1 * $3; }
| value '/' value
{ $$ = $1 / $3; }
| value '.' value
{
  unsigned int byte = (unsigned int) $1;
  unsigned int bit = (unsigned int) $3;
  if (byte > 0xFFU)
    {
      line_printf_error ("value out of range: 0x%X", $1);
      return -1;
    }
  if ((byte & 0xF0) != 0x20 && (!(byte & 0x80) || (byte & 0x07)))
    {
      line_printf_error ("not bit-addressable: 0x%02X", $1);
      return -1;
    }
  if (bit & 0xF8)
    {
      line_printf_error ("invalid bit number: %d", $3);
      return -1;
    }
  $$ = ($1 & 0x80) ? ($1 + $3) : ((($1 & 0x0F) << 3) + $3);
}
| '+' value %prec UNARY
{ $$ = $2; }
| '-' value %prec UNARY
{ $$ = -$2; }
| '~' value %prec UNARY
{ $$ = ~$2; }
| HIGH value %prec UNARY
{ $$ = ($2 >> 8) & 0xFF; }
| LOW value %prec UNARY
{ $$ = $2 & 0xFF; }
| '(' value ')'
{ $$ = $2; }
;

value8:
value
{
  if (((unsigned int) $1) > 0xFFU)
    {
      line_printf_error ("value out of range: 0x%X", $1);
      return -1;
    }
  $$ = $1;
}
;

value16:
value
{
  if (((unsigned int) $1) > 0xFFFFU)
    {
      line_printf_error ("value out of range: 0x%X", $1);
      return -1;
    }
  $$ = $1;
}
;

ireg:
REG
{ $$ = $1; }
;


inst:
code_inst
{ $$ = $1; }
| DS value
{
  int32_t i;
  if (parser8051->current_segment == SEG_8051_CODE)
    {
      for (i = 0; i < $2; i++, COUNTER (parser8051)++)
        parser8051_inst_process (parser8051, 0, 0x00);
      COUNTER (parser8051) -= $2;
    }
  $$ = $2;
}
| DBIT value
{ $$ = $2; }
;

code_inst:
NOP
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x00);
}

| SJMP value16
{
  int offset; $$ = 2;
  offset = ($2 - COUNTER (parser8051) - 2);
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $2);
      return -1;
    }
  parser8051_inst_process (parser8051, $$, 0x8000 + (offset & 0xFF));
}
| AJMP value16
{
  $$ = 2;
  if (($2 & 0xF800) != ((COUNTER (parser8051) + 2) & 0xF800))
    {
      line_printf_error ("address is too far: 0x%04X", $2);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           (($2 & 0x700) << 5 | 0x100) + ($2 & 0xFF));
}
| LJMP value16
{
  $$ = 3;
  parser8051_inst_process (parser8051, $$, (0x02 << 16) + $2);
}
| JMP '@' A '+' DPTR
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x73);
}
| JMP value16
{
  int offset;
  offset = ($2 - COUNTER (parser8051) - 2);
  if (offset >= -128 && 127 >= offset)
    {
      $$ = 2;
      parser8051_inst_process (parser8051, $$, 0x8000 + (offset & 0xFF));
    }
  else if (($2 & 0xF800) == ((COUNTER (parser8051) + 2) & 0xF800))
    {
      $$ = 2;
      parser8051_inst_process (parser8051, $$,
                               (($2 & 0x700) << 5 | 0x100) + ($2 & 0xFF));
    }
  else
    {
      $$ = 3;
      parser8051_inst_process (parser8051, $$, (0x02 << 16) + $2);
    }
}

| ACALL value16
{
  $$ = 2;
  if (($2 & 0xF800) != ((COUNTER (parser8051) + 2) & 0xF800))
    {
      line_printf_error ("address is too far: 0x%04X", $2);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           (($2 & 0x700) << 5 | 0x1100) + ($2 & 0xFF));
}
| LCALL value16
{
  $$ = 3;
  parser8051_inst_process (parser8051, $$, (0x12 << 16) + $2);
}
| CALL value16             {
  if (($2 & 0xF800) == ((COUNTER (parser8051) + 2) & 0xF800))
    {
      $$ = 2;
      parser8051_inst_process (parser8051, $$,
                               (($2 & 0x700) << 5 | 0x1100) + ($2 & 0xFF));
    }
  else
    {
      $$ = 3;
      parser8051_inst_process (parser8051, $$, (0x12 << 16) + $2);
    }
}
| RET
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x22);
}
| RETI
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x32);
}


| RR A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x03);
}
| RRC A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x13);
}
| RL A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x23);
}
| RLC A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x33);
}
| SWAP A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xC4);
}
| DA A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xD4);
}
| CLR A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xE4);
}
| CPL A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xF4);
}

| CPL value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xB200 + $2);
}
| CPL C
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xB3);
}
| CLR value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xC200 + $2);
}
| CLR C
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xC3);
}
| SETB value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xD200 + $2);
}
| SETB C
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xD3);
}
| PUSH value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xC000 + $2);
}
| POP value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xD000 + $2);
}

| DIV AB
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x84);
}
| MUL AB
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xA4);
}

| inc_dec A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, $1 + 0x04);
}
| inc_dec value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, (($1 + 0x05) << 8) + $2);
}
| inc_dec '@' ireg
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, $1 + 0x06 + $3);
}
| inc_dec REG
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, $1 + 8 + $2);
}
| INC DPTR
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xA3);
}

/* OP direct, A */
| bool_op value8 ',' A
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, (($1 + 0x02) << 8) + $2);
}
/* OP direct, #immed */
| bool_op value8 ',' '#' value8
{
  $$ = 3;
  parser8051_inst_process (parser8051, $$,
                           (($1 + 0x03) << 16) + ($2 << 8) + $5);
}
/* OP A, #immed */
| arith_op A ',' '#' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, (($1 + 0x04) << 8) + $5);
}
| bool_op A ',' '#' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, (($1 + 0x04) << 8) + $5);
}
/* OP A, direct */
| arith_op A ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, (($1 + 0x05) << 8) + $4);
}
| bool_op A ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, (($1 + 0x05) << 8) + $4);
}
| XCH A ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xC500 + $4);
}
/* OP A, @REG */
| arith_op A ',' '@' ireg
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, $1 + 0x06 + $5);
}
| bool_op A ',' '@' ireg
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, $1 + 0x06 + $5);
}
| XCH A ',' '@' ireg
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xC6 + $5);
}
| XCHD A ',' '@' ireg
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xD6 + $5);
}
/* OP A, REG */
| arith_op A ',' REG
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, $1 + 0x08 + $4);
}
| bool_op A ',' REG
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, $1 + 0x08 + $4);
}
| XCH A ',' REG
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xC8 + $4);
}

/* MOV <any>, #immed */
| MOV A ',' '#' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0x7400 + $5);
}
| MOV value8 ',' '#' value8
{
  $$ = 3;
  parser8051_inst_process (parser8051, $$, 0x750000 + ($2 << 8) + $5);
}
| MOV '@' ireg ',' '#' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, ((0x76 + $3) << 8) + $6);
}
| MOV REG ',' '#' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, ((0x78 + $2) << 8) + $5);
}
/* MOV direct, <any> */
| MOV value8 ',' value8
{
  $$ = 3;
  parser8051_inst_process (parser8051, $$, 0x850000 + ($4 << 8) + $2);
}
| MOV value8 ',' '@' ireg
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, ((0x86 + $5) << 8) + $2);
}
| MOV value8 ',' REG
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, ((0x88 + $4) << 8) + $2);
}
/* MOV <any>, direct */
| MOV '@' ireg ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, ((0xA6 + $3) << 8) + $5);
}
| MOV REG ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, ((0xA8 + $2) << 8) + $4);
}
/* MOV A, <any> */
| MOV A ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xE500 + $4);
}
| MOV A ',' '@' ireg
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xE6 + $5);
}
| MOV A ',' REG
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xE8 + $4);
}
/* MOV <any>, A */
| MOV value8 ',' A
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xF500 + $2);
}
| MOV '@' ireg ',' A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xF6 + $3);
}
| MOV REG ',' A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xF8 + $2);
}
/* special MOVs */
| MOV DPTR ',' '#' value16
{
  $$ = 3;
  parser8051_inst_process (parser8051, $$, 0x900000 + $5);
}
| MOVC A ',' '@' A '+' PC
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x83);
}
| MOVC A ',' '@' A '+' DPTR
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0x93);
}
| MOVX A ',' '@' ireg
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xE2 + $5);
}
| MOVX '@' ireg ',' A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xF2 + $3);
}
| MOVX A ',' '@' DPTR
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xE0);
}
| MOVX '@' DPTR ',' A
{
  $$ = 1;
  parser8051_inst_process (parser8051, $$, 0xF0);
}
/* CJNE */
| CJNE A ',' '#' value8 ',' value16
{
  int offset; $$ = 3;
  offset = $7 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $7);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           0xB40000 + ($5 << 8) + (offset & 0xFF));
}
| CJNE A ',' value8 ',' value16
{
  int offset; $$ = 3;
  offset = $6 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $6);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           0xB50000 + ($4 << 8) + (offset & 0xFF));
}
| CJNE '@' ireg ',' '#' value8 ',' value16
{
  int offset; $$ = 3;
  offset = $8 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $8);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           ((0xB6 + $3) << 16) + ($6 << 8) + (offset & 0xFF));
}
| CJNE REG ',' '#' value8 ',' value16
{
  int offset; $$ = 3;
  offset = $7 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $7);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           ((0xB8 + $2) << 16) + ($5 << 8) + (offset & 0xFF));
}
/* DJNZ */
| DJNZ value8 ',' value16
{
  int offset; $$ = 3;
  offset = $4 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $4);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           0xD50000 + ($2 << 8) + (offset & 0xFF));
}
| DJNZ REG ',' value16
{
  int offset; $$ = 2;
  offset = $4 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $4);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           ((0xD8 + $2) << 8) + (offset & 0xFF));
}
/* jumps on bits, carry or Acc */
| JBC value8 ',' value16
{
  int offset; $$ = 3;
  offset = $4 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $4);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           0x100000 + ($2 << 8) + (offset & 0xFF));
}
| JB value8 ',' value16
{
  int offset; $$ = 3;
  offset = $4 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $4);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           0x200000 + ($2 << 8) + (offset & 0xFF));
}
| JNB value8 ',' value16
{
  int offset; $$ = 3;
  offset = $4 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $4);
      return -1;
    }
  parser8051_inst_process (parser8051, $$,
                           0x300000 + ($2 << 8) + (offset & 0xFF));
}
| JC value16
{
  int offset; $$ = 2;
  offset = $2 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $2);
      return -1;
    }
  parser8051_inst_process (parser8051, $$, 0x4000 + (offset & 0xFF));
}
| JNC value16
{
  int offset; $$ = 2;
  offset = $2 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $2);
      return -1;
    }
  parser8051_inst_process (parser8051, $$, 0x5000 + (offset & 0xFF));
}
| JZ value16
{
  int offset; $$ = 2;
  offset = $2 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $2);
      return -1;
    }
  parser8051_inst_process (parser8051, $$, 0x6000 + (offset & 0xFF));
}
| JNZ value16
{
  int offset; $$ = 2;
  offset = $2 - COUNTER (parser8051) - $$;
  if (offset < -128 || 127 < offset)
    {
      line_printf_error ("address is too far: 0x%04X", $2);
      return -1;
    }
  parser8051_inst_process (parser8051, $$, 0x7000 + (offset & 0xFF));
}
/* bit arithmetic */
| ORL C ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0x7200 + $4);
}
| ANL C ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0x8200 + $4);
}
| MOV value8 ',' C
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0x9200 + $2);
}
| MOV C ',' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xA200 + $4);
}
| ORL C ',' '/' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xA000 + $5);
}
| ANL C ',' '/' value8
{
  $$ = 2;
  parser8051_inst_process (parser8051, $$, 0xB000 + $5);
}

| DB vargs
{ $$ = $2; COUNTER (parser8051) -= $2; }
;

inc_dec:
INC
{ $$ = 0x00; }
| DEC
{ $$ = 0x10; }
;

bool_op:
ORL
{ $$ = 0x40; }
| ANL
{ $$ = 0x50; }
| XRL { $$ = 0x60; }
;

arith_op:
ADD
{ $$ = 0x20; }
| ADDC
{ $$ = 0x30; }
| SUBB
{ $$ = 0x90; }
;

vargs:
vargs ',' value8
{
  parser8051_inst_process (parser8051, 0, $3);
  COUNTER (parser8051)++;
  $$ = $1 + 1;
}
| value8
{
  parser8051_inst_process (parser8051, 0, $1);
  COUNTER (parser8051)++;
  $$ = $1;
}
;

%%

int
yyerror (char *s)
{
  fprintf (stderr, "pass2, line %d: %s\n", 1+parser8051->line_no, s);
  return -1;
}
