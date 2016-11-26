/* Copyright (C) 2013, 2014, 2016 Luk Bettale

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

unsigned int inst_opcode;

int
parser8051_inst_process (struct parser8051_context *parser8051,
                         unsigned int len, unsigned int opcode)
{
  inst_opcode = opcode;
  return opcode;
}

static unsigned int read_inst8051 (char *inst)
{
  int n;

  yyin = fopen ("/tmp/inst8051.txt", "w+");
  if (yyin == NULL)
    {
      return -1;
    }

  n = 0;
  while (inst[n])
    fputc (inst[n++], yyin);
  fputc ('\n', yyin);
  rewind (yyin);

  parser8051 = malloc (sizeof (struct parser8051_context));
  assert (parser8051 != NULL);
  parser8051_init_context (parser8051);

  inst_opcode = 0;
  n = yyparse ();
  if (n != 0)
    inst_opcode = -1;

  fclose (yyin);
  free (parser8051);

  return inst_opcode;
}

int main (int argc, char *argv[])
{
  if (argc < 2)
    return 1;

  printf ("0x%06X\n", read_inst8051 (argv[1]));

  return 0;
}
