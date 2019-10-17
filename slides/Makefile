all: dist-detect-slides_de.html

%.html: %.adoc Makefile
	asciidoc $<
	@echo $@ done.

iwatch: all
	iwatch -c make -e close_write *.adoc
