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

%{
#include <stdint.h>
#include <stdio.h>

#include "parser8051.h"

#include "scan8051def.h"

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
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- (new DATA segment)",
                    parser8051->symbols[$1], $1);
  parser8051->values[$1] = SEG_8051_DATA;
  parser8051->types[$1] = TYPE_8051_CONST;
}
| ID SEGMENT XDATA
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- (new XDATA segment)",
                    parser8051->symbols[$1], $1);
  parser8051->values[$1] = SEG_8051_XDATA;
  parser8051->types[$1] = TYPE_8051_CONST;
}
| ID SEGMENT BIT
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- (new BIT segment)",
                    parser8051->symbols[$1], $1);
  parser8051->values[$1] = SEG_8051_BIT;
  parser8051->types[$1] = TYPE_8051_CONST;
}
| ID SEGMENT CODE
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- (new CODE segment)",
                    parser8051->symbols[$1], $1);
  parser8051->values[$1] = SEG_8051_CODE;
  parser8051->types[$1] = TYPE_8051_CONST;
}
| ID DATA value8
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  if ($3 & 0x80)
    {
      line_printf_error ("value out of range: 0x%X", $3);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- 0x%02X (new DATA value)",
                    parser8051->symbols[$1], $1, $3);
  parser8051->values[$1] = $3;
  parser8051->types[$1] = TYPE_8051_DATA;
}
| ID XDATA value16
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- 0x%04X (new XDATA value)",
                    parser8051->symbols[$1], $1, $3);
  parser8051->values[$1] = $3;
  parser8051->types[$1] = TYPE_8051_XDATA;
}
| ID BIT value8
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  if ($3 & 0x80)
    {
      line_printf_error ("value out of range: 0x%X", $3);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- 0x%02X (new BIT value)",
                    parser8051->symbols[$1], $1, $3);
  parser8051->values[$1] = $3;
  parser8051->types[$1] = TYPE_8051_BIT;
}
| ID CODE value16
{
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$2]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- 0x%04X (new CODE value)",
                    parser8051->symbols[$1], $1, $3);
  parser8051->values[$1] = $3;
  parser8051->types[$1] = TYPE_8051_CODE;
}
| ID EQU value
{
  if ($3 < 0)
    {
      line_print_error ("undefined rvalue");
      return -1;
    }
  if (parser8051->values[$1] != SEG_8051_NONE)
    {
      line_printf_error ("already defined: %s", parser8051->symbols[$1]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- 0x%X (new constant)",
                    parser8051->symbols[$1], $1, $3);
  parser8051->values[$1] = $3;
  parser8051->types[$1] = TYPE_8051_CONST;
}
| ID SET value
{
  if ($3 < 0)
    {
      line_print_error ("undefined rvalue");
      return -1;
    }
  if (parser8051->types[$1] != TYPE_8051_NONE)
    {
      line_printf_error ("cannot be redefined: %s", parser8051->symbols[$1]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- 0x%X (new variable)",
                    parser8051->symbols[$1], $1, $3);
  parser8051->values[$1] = $3;
  parser8051->types[$1] = TYPE_8051_NONE;
}
| USING value
{
  int i;
  if ($2 & 0xFC)
    {
      line_print_error ("invalid value");
      return -1;
    }
  for (i = 0; i < 8; i++)
    parser8051->values[i] = ($2 << 3) + i;
}
;

segment_head:
RSEG ID
{
  if (parser8051->values[$2] == SEG_8051_NONE)
    {
      line_printf_error ("undefined segment: %s", parser8051->symbols[$2]);
      return -1;
    }
  if (parser8051->values[$2] >= 0)
    {
      line_printf_error ("not a valid segment: %s", parser8051->symbols[$2]);
      return -1;
    }
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
  if ($3 < COUNTER (parser8051))
    {
      line_print_error ("overlapping segment");
      return -1;
    }
  COUNTER (parser8051) = $3;
}
| BSEG AT value
{
  parser8051->current_segment = SEG_8051_BIT;
  if ($3 < COUNTER (parser8051))
    {
      line_print_error ("overlapping segment");
      return -1;
    }
  COUNTER (parser8051) = $3;
}
| XSEG AT value
{
  parser8051->current_segment = SEG_8051_XDATA;
  if ($3 < COUNTER (parser8051))
    {
      line_print_error ("overlapping segment");
      return -1;
    }
  COUNTER (parser8051) = $3;
}
| CSEG AT value
{
  parser8051->current_segment = SEG_8051_CODE;
  if ($3 < COUNTER (parser8051))
    {
      line_print_error ("overlapping segment");
      return -1;
    }
  COUNTER (parser8051) = $3;
}
| ORG value
{
  if ($2 < COUNTER (parser8051))
    {
      line_print_error ("overlapping segment");
      return -1;
    }
  COUNTER (parser8051) = $2;
}
;

line:
segment_head
| symbols_decl
| label                         /* allows empty line */
| label inst
{
  COUNTER (parser8051) += $2;
  if (COUNTER (parser8051) > 65536)
    {
      line_print_error ("code is too large");
      return -1;
    }
}
;

program:
program line ENDL
{ parser8051->line_no++; }
| /* empty program */
;

label:
ID ':'
{
  if (parser8051->values[$1] != -1)
    {
      line_printf_error ("symbol already defined: %s",
                         parser8051->symbols[$1]);
      return -1;
    }
  line_printf_info ("%s: val[%d] <- 0x%x (%s)",
                    parser8051->symbols[$1], $1, COUNTER (parser8051),
                    parser8051->current_segment == SEG_8051_NONE ? "none" :
                    parser8051->current_segment == SEG_8051_DATA ? "data" :
                    parser8051->current_segment == SEG_8051_XDATA ? "xdata" :
                    parser8051->current_segment == SEG_8051_BIT ? "bit" :
                    parser8051->current_segment == SEG_8051_CODE ? "code" :
                    "impossible");
  parser8051->values[$1] = COUNTER (parser8051);
}
| /* no label */
;

value:
NUMBER
{ $$ = $1; }
| ID
{ $$ = parser8051->values[$1]; }
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
  if ($1 < 0 || $3 < 0)
    $$ = -1;
  else
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
  $$ = $1;
}
;

value16:
value
{
  $$ = $1;
}
;

ireg:
REG
{
  if ($1 > 1)
    {
      line_printf_error ("invalid register: @R%X", $1);
      return -1;
    }
  $$ = $1;
}
;

inst:
code_inst
{
  if (parser8051->current_segment != SEG_8051_CODE)
    {
      line_print_error ("should be in code segment");
      return -1;
    }
  $$ = $1;
}
| DS value
{
  if (parser8051->current_segment != SEG_8051_CODE
      && parser8051->current_segment != SEG_8051_DATA
      && parser8051->current_segment != SEG_8051_XDATA)
    {
      line_print_error ("should be in code or data/xdata segment");
      return -1;
    }
  if ($2 < 0)
    {
      line_print_error ("argument must be non-negative");
      return -1;
    }
  if ($2 + COUNTER (parser8051) > 0x10000)
    {
      line_print_error ("argument is too big");
      return -1;
    }
  $$ = $2;
}
| DBIT value
{
  if (parser8051->current_segment != SEG_8051_BIT)
    {
      line_print_error ("should be in bit addressable data segment");
      return -1;
    }
  if ($2 < 0)
    {
      line_print_error ("argument must be non-negative");
      return -1;
    }
  if ($2 + COUNTER (parser8051) > 0x80)
    {
      line_print_error ("argument is too big");
      return -1;
    }
 $$ = $2;
}
;

code_inst:
NOP
{ $$ = 1; }

| SJMP value16
{ $$ = 2; }
| AJMP value16
{ $$ = 2; }
| LJMP value16
{ $$ = 3; }
| JMP '@' A '+' DPTR
{ $$ = 1; }
| JMP value16
{
  int offset;
  if ($2 < 0)
    {
      line_print_error ("jmp (macro) to a forward label is unsupported. "
                        "use sjmp, ajmp or ljmp\n");
      return -1;
    }
  offset = ($2 - COUNTER (parser8051) - 2);
  if (offset >= -128 && 127 >= offset)
    $$ = 2;
  else if (($2 & 0xF800) == ((COUNTER (parser8051) + 2) & 0xF800))
    $$ = 2;
  else
    $$ = 3;
}

| ACALL value16
{ $$ = 2; }
| LCALL value16
{ $$ = 3; }
| CALL value16
{
  if ($2 < 0)
    {
      line_print_error ("call (macro) to a forward label is unsupported. "
                        "use acall or lcall\n");
      return -1;
    }
  if (($2 & 0xF800) == ((COUNTER (parser8051) + 2) & 0xF800))
    $$ = 2;
  else
    $$ = 3;
}

| RET
{ $$ = 1; }
| RETI
{ $$ = 1; }


| RR A
{ $$ = 1; }
| RRC A
{ $$ = 1; }
| RL A
{ $$ = 1; }
| RLC A
{ $$ = 1; }
| SWAP A
{ $$ = 1; }
| DA A
{ $$ = 1; }
| CLR A
{ $$ = 1; }
| CPL A
{ $$ = 1; }

| CPL value8
{ $$ = 2; }
| CPL C
{ $$ = 1; }
| CLR value8
{ $$ = 2; }
| CLR C
{ $$ = 1; }
| SETB value8
{ $$ = 2; }
| SETB C
{ $$ = 1; }

| PUSH value8
{ $$ = 2; }
| POP value8
{ $$ = 2; }

| DIV AB
{ $$ = 1; }
| MUL AB
{ $$ = 1; }

| inc_dec A
{ $$ = 1; }
| inc_dec value8
{ $$ = 2; }
| inc_dec '@' ireg
{ $$ = 1; }
| inc_dec REG
{ $$ = 1; }
| INC DPTR
{ $$ = 1; }

/* OP direct, A */
| bool_op value8 ',' A
{ $$ = 2; }
/* OP direct, #immed */
| bool_op value8 ',' '#' value8
{ $$ = 3; }
/* OP A, #immed */
| arith_op A ',' '#' value8
{ $$ = 2; }
| bool_op A ',' '#' value8
{ $$ = 2; }
/* OP A, direct */
| arith_op A ',' value8
{ $$ = 2; }
| bool_op A ',' value8
{ $$ = 2; }
| XCH A ',' value8
{ $$ = 2; }
/* OP A, @REG */
| arith_op A ',' '@' ireg
{ $$ = 1; }
| bool_op A ',' '@' ireg
{ $$ = 1; }
| XCH A ',' '@' ireg
{ $$ = 1; }
| XCHD A ',' '@' ireg
{ $$ = 1; }
/* OP A, REG */
| arith_op A ',' REG
{ $$ = 1; }
| bool_op A ',' REG
{ $$ = 1; }
| XCH A ',' REG
{ $$ = 1; }

/* MOV <any>, #immed */
| MOV A ',' '#' value8
{ $$ = 2; }
| MOV value8 ',' '#' value8
{ $$ = 3; }
| MOV '@' ireg ',' '#' value8
{ $$ = 2; }
| MOV REG ',' '#' value8
{ $$ = 2; }
/* MOV direct, <any> */
| MOV value8 ',' value8
{ $$ = 3; }
| MOV value8 ',' '@' ireg
{ $$ = 2; }
| MOV value8 ',' REG
{ $$ = 2; }
/* MOV <any>, direct */
| MOV '@' ireg ',' value8
{ $$ = 2; }
| MOV REG ',' value8
{ $$ = 2; }
/* MOV A, <any> */
| MOV A ',' value8
{ $$ = 2; }
| MOV A ',' '@' ireg
{ $$ = 1; }
| MOV A ',' REG
{ $$ = 1; }
/* MOV <any>, A */
| MOV value8 ',' A
{ $$ = 2; }
| MOV '@' ireg ',' A
{ $$ = 1; }
| MOV REG ',' A
{ $$ = 1; }
/* special MOVs */
| MOV DPTR ',' '#' value16
{ $$ = 3; }
| MOVC A ',' '@' A '+' PC
{ $$ = 1; }
| MOVC A ',' '@' A '+' DPTR
{ $$ = 1; }
| MOVX A ',' '@' ireg
{ $$ = 1; }
| MOVX '@' ireg ',' A
{ $$ = 1; }
| MOVX A ',' '@' DPTR
{ $$ = 1; }
| MOVX '@' DPTR ',' A
{ $$ = 1; }
/* CJNE */
| CJNE A ',' '#' value8 ',' value16
{ $$ = 3; }
| CJNE A ',' value8 ',' value16
{ $$ = 3; }
| CJNE '@' ireg ',' '#' value8 ',' value16
{ $$ = 3; }
| CJNE REG ',' '#' value8 ',' value16
{ $$ = 3; }
/* DJNZ */
| DJNZ value8 ',' value16
{ $$ = 3; }
| DJNZ REG ',' value16
{ $$ = 2; }
/* jumps on bits, carry or Acc */
| JBC value8 ',' value16
{ $$ = 3; }
| JB value8 ',' value16
{ $$ = 3; }
| JNB value8 ',' value16
{ $$ = 3; }
| JC value16
{ $$ = 2; }
| JNC value16
{ $$ = 2; }
| JZ value16
{ $$ = 2; }
| JNZ value16
{ $$ = 2; }
/* bit arithmetic */
| ORL C ',' value8
{ $$ = 2; }
| ANL C ',' value8
{ $$ = 2; }
| MOV value8 ',' C
{ $$ = 2; }
| MOV C ',' value8
{ $$ = 2; }
| ORL C ',' '/' value8
{ $$ = 2; }
| ANL C ',' '/' value8
{ $$ = 2; }

| DB vargs
{ $$ = $2; }
;

inc_dec:
INC
| DEC
;

bool_op:
ORL
| ANL
| XRL
;

arith_op:
ADD
| ADDC
| SUBB
;

vargs:
vargs ',' value8
{ $$ = $1 + 1; }
| value8
{ $$ = 1; }
;

%%

int
yyerror (char *s)
{
  fprintf (stderr, "pass1, line %d: %s\n", 1+parser8051->line_no, s);
  return -1;
}
