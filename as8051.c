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
#include <string.h>

#include <parser/parser8051.h>

FILE *stream;

int
parser8051_inst_process (struct parser8051_context *parser8051,
                         unsigned int len, unsigned int opcode)
{
  if (parser8051->current_segment != SEG_8051_CODE)
    return -1;

  if (len == 3)
    fputc ((opcode >> 16) & 0xFF, stream);
  if (len >= 2)
    fputc ((opcode >> 8) & 0xFF, stream);
  fputc (opcode & 0xFF, stream);

  return opcode;
}

static inline void
line2hex (unsigned short nb, unsigned char i, unsigned char *line)
{
  unsigned int j;
  unsigned char ck = 0;
  printf (":%02X%04X00", i, nb);
  ck -= i;
  ck -= nb & 0xFF;
  ck -= (nb >> 8) & 0xFF;
  for (j = 0; j < i; j++)
    {
      ck -= line[j];
      printf ("%02X", line[j]);
    }
  printf ("%02X\n", ck);
}

int main (int argc, char *argv[])
{
  int n;
  unsigned char i;
  unsigned short nb;
  unsigned char line[16];

  if (argc > 1)
    {
      if (strcmp (argv[1], "-b") == 0)
        {
          stream = stdout;
          argc--;
          argv++;
        }
    }
  if (argc < 2)
    {
      fprintf (stderr, "filename needed\n");
      return -1;
    }

  if (!stream)
    stream = tmpfile ();
  if (!stream)
    return 1;

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

  fclose (yyin);
  free (parser8051);

  if (stream == stdout)
    return 0;

  rewind (stream);

  i = 0;
  nb = 0;
  while ((n = fgetc (stream)) != EOF)
    {
      line[i++] = (unsigned char) n;
      nb++;
      if (i == 16)
        {
          line2hex (nb - i, i, line);
          i = 0;
        }
    }
  fclose (stream);
  if (i)
    line2hex (nb - i, i, line);
  printf (":00000001FF\n");

  return 0;
}
