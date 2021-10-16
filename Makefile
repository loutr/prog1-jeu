SHELL	= /bin/bash
CC	= ocamlc
CCOPT	= ocamlopt
CFLAGS	= -I +graphics -I lib -I src

vpath	%.ml	src
.PHONY: clean all

sudoku: lib/dynamique.cma lib/assets.cma global.ml logic.ml render.ml main.ml 
	$(CC) $(CFLAGS) unix.cma graphics.cma $^ -o $@

sudoku.bin: lib/dynamique.cmxa lib/assets.cmxa global.ml logic.ml render.ml main.ml
	$(CCOPT) $(CFLAGS) unix.cmxa graphics.cmxa $^ -o $@

lib/%.cma: lib/%.ml
	$(CC) $(CFLAGS) -a $< -o $@

lib/%.cmxa: lib/%.ml
	$(CCOPT) $(CFLAGS) -a $< -o $@

lib/assets.ml: lib/assets/*.bmp lib/assets/parser.py
	cd lib/assets; python3 parser.py

clean:
	rm -f {src,lib}/*.{cmo,cmx,o,cma,cmxa,a,cmi}

all: sudoku sudoku.bin
