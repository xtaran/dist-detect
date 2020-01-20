all: dist-detect-slides_de.html dist-detect-slides_en.html dist-detect-slides_en_25.html

%.html: %.adoc Makefile
	asciidoc $<
	@echo $@ done.

iwatch: all
	iwatch -c make -e close_write *.adoc
