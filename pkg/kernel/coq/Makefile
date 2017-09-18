FLAGS=-R . Kernel

all: common syntax types

%.vo: %.v
	coqc ${FLAGS} -o $@ $^

common: CpdtTactics.vo Common.vo CommonTactics.vo

syntax: common SyntaxRaw.vo Syntax.vo

types: common syntax ObjectModel.vo

clean:
	rm -f *.aux *.vo *.glob .*.aux
