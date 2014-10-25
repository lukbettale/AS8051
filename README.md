AS8051
======

Assembler (and pretty printer) for 8051.

This program is a simple 8051 assembler.

AS8051 provides:

 - a program called `as8051` which transform a 8051 assembly file into
   a hex format file or a binary file;

 - a program called `pp8051` which rewrite a 8051 assembly file to
   remove labels and comments.


Installation: `make && make install`
 - You should run make install as root in order to install the
   programs in `/usr/local`.
 - You may specify another
   installation program by assigning the environment variable `PREFIX`:

`PREFIX="/my/own/path" make install`
              

Usage: `as8051 [-b] input.asm`

The assembled output comes out from stdout.

`-b`     outputs a binary file instead of the hex format.
