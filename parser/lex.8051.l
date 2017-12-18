/* Copyright (C) 2013, 2016 Luk Bettale

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
#include <assert.h>
#include <stdio.h>
#include "y.tab.h"

#include "parser8051.h"

#define yyerror lex_yyerror

extern struct parser8051_context *parser8051;

static int yyerror (char *s);
extern int yylval;
static int sym_lookup (char *s);
static int res_word (char *s);
%}

%option nounput
%option noinput

%%

[ \t\r]           ;
;.*               ;
\n                return ENDL;

[0-9]+            {
  sscanf (yytext, "%d", &yylval);
  return NUMBER;
}

'.'               {
  yylval = yytext[1];
  return NUMBER;
}

0x[0-9a-fA-F]+    {
  sscanf (yytext+2, "%x", (unsigned int *) &yylval);
  return NUMBER;
}

[0-9][0-9a-fA-F]*[hH]  {
  sscanf (yytext, "%x", (unsigned int *) &yylval);
  return NUMBER;
}

[01]+[bB]  {
  yylval = 0;
  do
    {
      yylval <<= 1;
      yylval |= *(yytext++) - '0';
    }
  while ((*yytext != 'b') && (*yytext != 'B'));
  return NUMBER;
}

[-+*/&^|$():#@,.]          return yytext[0];

[rR][0-7]         {
  yylval = yytext[1] - '0';
  return REG;
}

[a-zA-Z_?][0-9a-zA-Z_?]* {
  int token;

  if ((token = res_word (yytext)) != 0)
    return token;

  yylval = sym_lookup (yytext);

  return ID;
}

.                      return yyerror ("Invalid token");

%%

static int
sym_lookup (char *s)
{
  int i;

  for (i = 0; parser8051->symbols[i][0] != '\0' && i < 65536; i++)
    {
      if (strcmp (s, parser8051->symbols[i]) == 0)
        return i;
    }
  assert (i < 65536);
  strcpy (parser8051->symbols[i], s);

  return i;
}

static int
res_word (char *s)
{
  if (strcmp (s, "A") == 0 || strcmp (s, "a") == 0)
    return A;
  if (strcmp (s, "C") == 0 || strcmp (s, "c") == 0)
    return C;
  if (strcmp (s, "DPTR") == 0 || strcmp (s, "dptr") == 0)
    return DPTR;
  if (strcmp (s, "PC") == 0 || strcmp (s, "pc") == 0)
    return PC;
  if (strcmp (s, "AB") == 0 || strcmp (s, "AB") == 0)
    return AB;

  if (strcmp (s, "NOP") == 0 || strcmp (s, "nop") == 0)
    return NOP;

  if (strcmp (s, "SJMP") == 0 || strcmp (s, "sjmp") == 0)
    return SJMP;
  if (strcmp (s, "AJMP") == 0 || strcmp (s, "ajmp") == 0)
    return AJMP;
  if (strcmp (s, "LJMP") == 0 || strcmp (s, "ljmp") == 0)
    return LJMP;
  if (strcmp (s, "JMP") == 0 || strcmp (s, "jmp") == 0)
    return JMP;

  if (strcmp (s, "ACALL") == 0 || strcmp (s, "acall") == 0)
    return ACALL;
  if (strcmp (s, "LCALL") == 0 || strcmp (s, "lcall") == 0)
    return LCALL;
  if (strcmp (s, "CALL") == 0 || strcmp (s, "call") == 0)
    return CALL;
  if (strcmp (s, "RET") == 0 || strcmp (s, "ret") == 0)
    return RET;
  if (strcmp (s, "RETI") == 0 || strcmp (s, "reti") == 0)
    return RETI;

  if (strcmp (s, "MOV") == 0 || strcmp (s, "mov") == 0)
    return MOV;
  if (strcmp (s, "MOVX") == 0 || strcmp (s, "movx") == 0)
    return MOVX;
  if (strcmp (s, "MOVC") == 0 || strcmp (s, "movc") == 0)
    return MOVC;
  if (strcmp (s, "XCH") == 0 || strcmp (s, "xch") == 0)
    return XCH;
  if (strcmp (s, "XCHD") == 0 || strcmp (s, "xchd") == 0)
    return XCHD;

  if (strcmp (s, "ADD") == 0 || strcmp (s, "add") == 0)
    return ADD;
  if (strcmp (s, "ADDC") == 0 || strcmp (s, "addc") == 0)
    return ADDC;
  if (strcmp (s, "SUBB") == 0 || strcmp (s, "subb") == 0)
    return SUBB;
  if (strcmp (s, "XRL") == 0 || strcmp (s, "xrl") == 0)
    return XRL;
  if (strcmp (s, "ANL") == 0 || strcmp (s, "anl") == 0)
    return ANL;
  if (strcmp (s, "ORL") == 0 || strcmp (s, "orl") == 0)
    return ORL;

  if (strcmp (s, "MUL") == 0 || strcmp (s, "mul") == 0)
    return MUL;
  if (strcmp (s, "DIV") == 0 || strcmp (s, "div") == 0)
    return DIV;

  if (strcmp (s, "RR") == 0 || strcmp (s, "rr") == 0)
    return RR;
  if (strcmp (s, "RRC") == 0 || strcmp (s, "rrc") == 0)
    return RRC;
  if (strcmp (s, "RL") == 0 || strcmp (s, "rl") == 0)
    return RL;
  if (strcmp (s, "RLC") == 0 || strcmp (s, "rlc") == 0)
    return RLC;
  if (strcmp (s, "SWAP") == 0 || strcmp (s, "swap") == 0)
    return SWAP;
  if (strcmp (s, "DA") == 0 || strcmp (s, "da") == 0)
    return DA;
  if (strcmp (s, "CLR") == 0 || strcmp (s, "clr") == 0)
    return CLR;
  if (strcmp (s, "CPL") == 0 || strcmp (s, "cpl") == 0)
    return CPL;
  if (strcmp (s, "SETB") == 0 || strcmp (s, "setb") == 0)
    return SETB;

  if (strcmp (s, "JZ") == 0 || strcmp (s, "jz") == 0)
    return JZ;
  if (strcmp (s, "JNZ") == 0 || strcmp (s, "jnz") == 0)
    return JNZ;
  if (strcmp (s, "JC") == 0 || strcmp (s, "jc") == 0)
    return JC;
  if (strcmp (s, "JNC") == 0 || strcmp (s, "jnc") == 0)
    return JNC;
  if (strcmp (s, "JB") == 0 || strcmp (s, "jb") == 0)
    return JB;
  if (strcmp (s, "JNB") == 0 || strcmp (s, "jnb") == 0)
    return JNB;
  if (strcmp (s, "JBC") == 0 || strcmp (s, "jbc") == 0)
    return JBC;

  if (strcmp (s, "CJNE") == 0 || strcmp (s, "cjne") == 0)
    return CJNE;
  if (strcmp (s, "DJNZ") == 0 || strcmp (s, "djnz") == 0)
    return DJNZ;

  if (strcmp (s, "PUSH") == 0 || strcmp (s, "push") == 0)
    return PUSH;
  if (strcmp (s, "POP") == 0 || strcmp (s, "pop") == 0)
    return POP;
  if (strcmp (s, "INC") == 0 || strcmp (s, "inc") == 0)
    return INC;
  if (strcmp (s, "DEC") == 0 || strcmp (s, "dec") == 0)
    return DEC;

  if (strcmp (s, "SEGMENT") == 0 || strcmp (s, "segment") == 0)
    return SEGMENT;
  if (strcmp (s, "RSEG") == 0 || strcmp (s, "rseg") == 0)
    return RSEG;
  if (strcmp (s, "AT") == 0 || strcmp (s, "at") == 0)
    return AT;

  if (strcmp (s, "DSEG") == 0 || strcmp (s, "dseg") == 0)
    return DSEG;
  if (strcmp (s, "BSEG") == 0 || strcmp (s, "bseg") == 0)
    return BSEG;
  if (strcmp (s, "XSEG") == 0 || strcmp (s, "xseg") == 0)
    return XSEG;
  if (strcmp (s, "CSEG") == 0 || strcmp (s, "cseg") == 0)
    return CSEG;
  if (strcmp (s, "ORG") == 0 || strcmp (s, "org") == 0)
    return ORG;

  if (strcmp (s, "DATA") == 0 || strcmp (s, "data") == 0)
    return DATA;
  if (strcmp (s, "XDATA") == 0 || strcmp (s, "xdata") == 0)
    return XDATA;
  if (strcmp (s, "BIT") == 0 || strcmp (s, "bit") == 0)
    return BIT;
  if (strcmp (s, "CODE") == 0 || strcmp (s, "code") == 0)
    return CODE;

  if (strcmp (s, "LSH") == 0 || strcmp (s, "lsh") == 0)
    return LSH;
  if (strcmp (s, "RSH") == 0 || strcmp (s, "rsh") == 0)
    return RSH;

  if (strcmp (s, "HIGH") == 0 || strcmp (s, "high") == 0)
    return HIGH;
  if (strcmp (s, "LOW") == 0 || strcmp (s, "low") == 0)
    return LOW;

  if (strcmp (s, "END") == 0 || strcmp (s, "end") == 0)
    return END;

  if (strcmp (s, "DS") == 0 || strcmp (s, "ds") == 0)
    return DS;
  if (strcmp (s, "DBIT") == 0 || strcmp (s, "dbit") == 0)
    return DBIT;
  if (strcmp (s, "DB") == 0 || strcmp (s, "db") == 0)
    return DB;

  if (strcmp (s, "EQU") == 0 || strcmp (s, "equ") == 0)
    return EQU;
  if (strcmp (s, "SET") == 0 || strcmp (s, "set") == 0)
    return SET;

  if (strcmp (s, "USING") == 0 || strcmp (s, "using") == 0)
    return USING;

  return 0;
}

static int
yyerror (char *s)
{
  fprintf (stderr, "line %d: %s\n", 1+parser8051->line_no, s);
  return -1;
}
