SRCDIR := src
FIGDIR := $(SRCDIR)/figures
BUILDDIR := build
TEXFIGS := $(wildcard $(FIGDIR)/*.tex)
PNGFIGS := $(TEXFIGS:.tex=.png)
TOOLSDIR := tools

DPI := 300

.PHONY: all figures html clean

all: figures html

FIGSRC := $(SRCDIR)/figures
FIGBUILD := $(BUILDDIR)/figures

TEXFIGS := $(wildcard $(FIGSRC)/*.tex)
PNGFIGS := $(TEXFIGS:$(FIGSRC)/%.tex=$(FIGSRC)/%.png)

DPI := 300

.PHONY: figures clean

figures: $(PNGFIGS) pumlfigures

pumlfigures:
	 java -jar $(TOOLSDIR)/plantuml.jar src/figures/*.puml --format svg


# Rule: src/figures/foo.tex → src/figures/foo.png
$(FIGSRC)/%.png: $(FIGSRC)/%.tex
	mkdir -p $(FIGBUILD)
	cp $< $(FIGBUILD)/$*.tex
	cd $(FIGBUILD) && \
	pdflatex -interaction=nonstopmode -halt-on-error $*.tex && \
	pdftocairo -png -r $(DPI) $*.pdf $* && \
	mv $*-1.png $(abspath $(FIGSRC))/$*.png

html:
	make4ht -u -e make4ht.mk4 -d $(BUILDDIR)/html -a debug -f html5 $(SRCDIR)/main.tex
	cat $(SRCDIR)/style.css >> $(BUILDDIR)/html/main.css
	rm main.*

clean:
	rm -f $(FIGDIR)/*.aux $(FIGDIR)/*.log \
	      $(FIGDIR)/*.pdf $(FIGDIR)/*-*.png

dev-install:
	cd $(TOOLSDIR) && wget -O plantuml.jar https://github.com/plantuml/plantuml/releases/download/v1.2025.10/plantuml-1.2025.10.jar
