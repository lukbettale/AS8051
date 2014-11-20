CC = gcc
CPPFLAGS = -D_POSIX_SOURCE -I.
CFLAGS = -Wall -Wextra -Wmissing-declarations -fPIC -std=c99 -pedantic -O3
LDFLAGS = -s -L.
YFLAGS = -d

PREFIX ?= /usr/local

EXE = as8051 pp8051
TARGETS = $(EXE)

PRINTOBJ = print/lib8051print.o

LEXYACCOBJ = parser/yacc.8051.o parser/yacc.scan_8051.o parser/lex.8051.o
PARSEROBJ = parser/parser8051.o

OBJFILES = $(PRINTOBJ) $(LEXYACCOBJ) $(PARSEROBJ) $(SRCFILES:.c=.o)

all: $(TARGETS)

as8051: LDLIBS += -lfl
as8051: $(PARSEROBJ) $(LEXYACCOBJ)

pp8051: LDLIBS += -lfl
pp8051: $(PARSEROBJ) $(LEXYACCOBJ) $(PRINTOBJ)

install: $(TARGETS)
	mkdir -p $(PREFIX)/bin
	cp $(EXE) $(PREFIX)/bin

clean:
	rm -f $(OBJFILES) $(TARGETS) y.tab.h

%.hex: %.asm as8051
	./as8051 $< >$@ || rm -f $@

%.bin: %.asm as8051
	./as8051 -b $< >$@ || rm -f $@

.PHONY: all clean
