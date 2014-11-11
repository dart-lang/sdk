NAME=dartLangSpec
SPEC=$(NAME).tex
HASH=$(NAME)-hash.tex
LIST=$(NAME)-list.txt
HASHER=../../tools/addlatexhash.dart

pdf:
	pdflatex $(SPEC)
	pdflatex $(SPEC)
	pdflatex $(SPEC)

pdfhash: hash_and_list
	pdflatex $(HASH)
	pdflatex $(HASH)
	pdflatex $(HASH)

dvi:
	latex $(SPEC)
	latex $(SPEC)
	latex $(SPEC)

dvihash: hash_and_list
	latex $(HASH)
	latex $(HASH)
	latex $(HASH)

hash_and_list:
	dart $(HASHER) $(SPEC) $(HASH) $(LIST)

help:
	@echo "Goals:"
	@echo "  pdf, dvi: generate the pdf/dvi file containing the spec"
	@echo "  pdfhash, dvihash: ditto, with location markers filled in"
	@echo "  cleanish: remove [pdf]latex generated intermediate files"
	@echo "  clean: remove all generated files"

cleanish:
	rm -f *.aux *.log *.toc *.out

clean: cleanish
	rm -f *.dvi *.pdf $(HASH) $(LIST)

