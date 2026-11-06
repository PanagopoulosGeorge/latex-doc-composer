---
name: latex-compile
description: Compile a LaTeX document with latexmk and fix build errors and warnings. Use whenever a document needs building, the user asks to compile/build/render the PDF, or a compile fails.
---
# Compiling a document

```bash
scripts/build.sh <doc-dir>            # e.g. docs/my-thesis   (or: make build D=docs/my-thesis)
scripts/build.sh <doc-dir> --clean    # wipe aux files first; use when state looks stale
scripts/build.sh <doc-dir> --watch    # continuous rebuild (for the user, not for you)
```
- The main file comes from `@default_files` in `.latexmkrc`, then `main.tex`, then the only file with `\documentclass`. Override with `MAIN=foo.tex`.
- Output goes to `<doc-dir>/build/<main>.pdf` (`$out_dir` in `.latexmkrc`).
- latexmk runs the engine, BibTeX and makeindex as many times as needed. Don't call pdflatex by hand.
- The script prints the first errors as `file:line: message`, and any undefined citations or references.

## Fix loop
1. Read the **first** error only. Later errors are usually caused by it.
2. Open the cited `file:line`. The actual mistake is often a line or two **above** it (an unclosed brace, a missing `\\`, a missing `$`).
3. Fix it, rebuild, and repeat until the build succeeds.
4. Then triage warnings in `build/<main>.log`:
   - `Citation 'x' undefined` → the key is missing from the .bib, or it's a typo. Check with `grep -n '{x,' *.bib`.
   - `Reference 'x' undefined` → the `\label` is missing or misspelled. Labels must come **after** `\caption`.
   - `There were undefined references` / `Rerun` → latexmk handles these; if they persist, the problem is real.
   - `Overfull \hbox (12.3pt too wide)` → text sticks out into the margin. Fix any over ~5pt in final versions: reword, add `\allowbreak`, or use `\url{}` for long strings.
   - `Underfull` → usually ignore.
   - `Font shape ... undefined` → usually harmless. Load `lmodern` with T1.
5. Look up specific error messages in the `latex-internals` skill (`references/errors.md`).

## Engines
- **pdflatex**: the default in the templates. Fastest and most compatible.
- **xelatex / lualatex**: use them for system fonts (`fontspec`) or heavy Unicode (e.g. Greek without babel tricks). Switch by setting `$pdf_mode = 5` (xelatex) or `4` (lualatex) in `.latexmkrc`. Remove `fontenc`/`inputenc` when switching.
- Don't mix: a document that loads `fontspec` won't compile under pdflatex.

## Before telling the user it's done
- The build exits 0 and the PDF timestamp is new.
- There are no undefined references or citations.
- Report the PDF path and anything you left unfixed.
