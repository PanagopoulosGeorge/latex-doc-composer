---
name: latex-internals
description: How LaTeX works under the hood - the compile pipeline, aux files, macros and expansion, catcodes and \makeatletter, classes vs packages, package load order, floats, fonts/encodings, and how to debug. Use when diagnosing a non-obvious LaTeX error, writing or editing a .cls/.sty or macros, or when a fix needs understanding rather than trial and error.
---
# LaTeX internals for debugging

## The pipeline: why several runs are needed
```
main.tex ──pdflatex──► main.aux (labels, citations), .toc/.lof, .idx, main.pdf
main.aux ──bibtex────► main.bbl   (reads \citation{} + \bibdata{} + .bst)
main.idx ──makeindex─► main.ind
pdflatex again: reads .aux/.bbl/.toc → resolves refs, but page numbers may shift
pdflatex again: stable
```
- `??` in the PDF means a label isn't resolved yet (another run is needed) or doesn't exist.
- `[?]` means a citation is missing from `.bbl`: bibtex didn't run, or the key isn't in the `.bib`.
- **latexmk** tracks these dependencies and reruns until stable. Its state lives in `.fdb_latexmk`. If it gets confused, `scripts/build.sh <doc> --clean`.
- A corrupt `.aux` from a crashed run can cause errors that look unrelated (e.g. in `\@writefile`). Clean and rebuild.
- biblatex uses `biber` and `.bcf`/`.run.xml` instead of bibtex and `.bst`. You can't mix natbib and biblatex.

## Reading errors
```
./chapters/04-method.tex:37: Undefined control sequence.
l.37 \sysnme
            {} is fast
```
- `file:line` (from `-file-line-error`) gives the file and line where TeX **noticed** the problem.
- The `l.37` line is split at the exact point TeX had read up to.
- With `-interaction=nonstopmode` TeX keeps going after errors. **Only the first error is reliable.**
- Runaway argument / `File ended while scanning use of \foo` means a missing `}`. The error points far below the cause. Bisect: comment out halves of the file.
- Common messages and fixes are in `references/errors.md`.

## Macros and expansion
- `\newcommand{\x}[n]{...}` errors if `\x` already exists. `\renewcommand` errors if it doesn't. `\providecommand` defines only if missing. `\def` silently overwrites anything, which is dangerous in documents but normal in .cls/.sty files.
- `\NewDocumentCommand{\x}{m o}{...}` (built into LaTeX since 2020) is the modern interface, with optional arguments anywhere.
- TeX **expands** macros (replaces them with their definitions) until it reaches primitives. `\edef` expands at definition time; `\def` expands at use time.
- `\expandafter\a\b` expands `\b` once before `\a` sees it. `\csname name\endcsname` builds a command name from text. The thesis class uses it in `\setmeta`.
- **Fragile commands in moving arguments**: section titles and captions are written to `.toc`/`.lof`. A fragile command there breaks. Use `\protect\cmd`, or give a short form, `\section[plain]{fancy}`.
- Debugging: `\show\cmd` prints a command's definition to the log and terminal. `\meaning\cmd` prints it into the PDF. `\tracingmacros=2 \tracingonline=1` traces expansion.

## Catcodes and `@`
- Every character has a category code. `\` = escape, `{}` = group, `$` = math, `%` = comment, `&` = alignment, `#` = parameter, `^_` = sub/superscript.
- `@` is a **letter** inside .cls/.sty files, so internal names like `\@thesisauthor` work there. In a .tex document it's "other", so `\@foo` reads as `\@` followed by `foo`. Wrap internal-macro code in a document with `\makeatletter ... \makeatother`.
- Verbatim (`\verb`, `lstlisting`) changes catcodes, so it **can't appear inside another command's argument** (e.g. inside `\footnote{}` or `\caption{}`).

## Classes vs packages
- `.cls`: one per document (`\documentclass`). It defines the page layout and sectioning, and may `\LoadClass` a base (`book`, `article`). It uses `\ProvidesClass`, `\DeclareOption`, `\ProcessOptions`, `\RequirePackage`.
- `.sty`: any number (`\usepackage`). It uses `\ProvidesPackage`.
- Files resolve from the document's folder first, then the TeX tree. `kpsewhich foo.sty` shows which file is used.
- Option clash (`Option clash for package xcolor`): two loads with different options. Load it once with all options, or call `\PassOptionsToPackage{table}{xcolor}` **before** the first load.

## Package load order (rules that save hours)
1. `fontenc`, `inputenc` (pdflatex only; UTF-8 is the default since 2018), `babel`.
2. Most packages.
3. `hyperref` **near the very end**. It patches many commands.
4. After hyperref: `cleveref`, `glossaries`, `bookmark`.
5. `algorithm` + `algpseudocode` (algorithmicx); don't mix with `algorithmic`.
6. `subcaption`, not the obsolete `subfigure`/`subfig`, which conflict with `caption`.

## Floats
- Figures and tables float. TeX places them by `[htbp]` preference and by `\topfraction` and the related parameters.
- `[H]` (from the `float` package) forces "here", but can leave big gaps.
- `Too many unprocessed floats`: floats are queued faster than they can be placed. Add `\clearpage`, loosen the fractions (the thesis template already does), or reduce the number of floats.
- `\label` must come **after** `\caption`. The caption sets the counter that the label refers to.

## Fonts and encodings
- pdflatex with T1: `\usepackage[T1]{fontenc}` + `lmodern` gives proper hyphenation of accented words and copy-pasteable PDFs.
- Greek or other scripts under pdflatex need babel language support plus font packages (the thesis class `greek` option). Under xelatex/lualatex, use `fontspec` with a system font that has the glyphs.
- `Missing character: There is no X in font` means the glyph isn't in the current font. Switch fonts or engine.

## Debugging method
1. Reproduce with `--clean`.
2. Find the **first** error and its file:line.
3. Bisect. Comment out `\input`s, then halves of the offending file, until the smallest failing snippet remains.
4. Make a minimal example (`\documentclass{article}` + the offending package + the snippet). If it fails there too, it's the package or your usage. If it doesn't, it's an interaction (load order, class).
5. Check package documentation: `texdoc <pkg>`. The local docs match your installed version.
