# latexmk configuration (pdflatex + BibTeX + makeindex, output in ./build)
$pdf_mode = 1;
$pdflatex = 'pdflatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
$bibtex_use = 2;
$makeindex = 'makeindex %O -o %D %S';
$out_dir = 'build';
@default_files = ('main.tex');
