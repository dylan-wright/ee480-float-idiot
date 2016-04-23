all: notes.pdf

notes.pdf: notes.tex notes.bib
	pdflatex notes.tex
	bibtex notes.aux
	pdflatex notes.tex
	pdflatex notes.tex

clean:
	rm notes.pdf notes.aux notes.log notes.bbl notes.blg notes.out
