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
#include <stdlib.h>
#include <stdio.h>

#include <print/lib8051print.h>
#include <parser/parser8051.h>

int
parser8051_inst_process (struct parser8051_context *parser8051,
                         unsigned int len, unsigned int opcode)
{
  uint8_t IR[6];

  IR[0] = (opcode >> 16) & 0xFF;
  IR[1] = (opcode >> 8) & 0xFF;
  IR[2] = opcode & 0xFF;
  IR[3] = len;
  IR[4] = len;
  IR[5] = len;

  fprintf (stdout, "x%04X:  ", COUNTER (parser8051));
  if (len)
    fprint_op (stdout, &IR[3 - len], COUNTER (parser8051));
  else
    fprintf (stdout, "DB    0x%02X                      ", opcode & 0xFF);
  fprintf (stdout, "        ;; ");
  fprintf (stdout, "l.%d", 1 + parser8051->line_no);
#ifdef PRINT_OPCODE
  fprintf (stdout, "  (opcode = 0x");
  if (len == 3)
    fprintf (stdout, "%02X", (opcode >> 16) & 0xFF);
  if (len >= 2)
    fprintf (stdout, "%02X", (opcode >> 8) & 0xFF);
  fprintf (stdout, "%02X", opcode & 0xFF);
  fprintf (stdout, ")");
#endif  /* PRINT_OPCODE */
  fprintf (stdout, "\n");

  return opcode;
}

int main (int argc, char *argv[])
{
  int n;

  if (argc < 2)
    {
      fprintf (stderr, "filename needed\n");
      return -1;
    }

  yyin = fopen (argv[1], "r");
  if (yyin == NULL)
    {
      fprintf (stderr, "invalid filename: %s\n", argv[1]);
      return -1;
    }

  parser8051 = malloc (sizeof (struct parser8051_context));
  assert (parser8051 != NULL);
  parser8051_init_context (parser8051);

  n = scan_yyparse ();
  if (n != 0)
    return n;

  from_top (parser8051);
  rewind (yyin);

  n = yyparse ();

  free (parser8051);

  return n;
}
