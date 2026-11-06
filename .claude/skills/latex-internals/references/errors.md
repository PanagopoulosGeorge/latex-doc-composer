# Common LaTeX errors

| Message | Usual cause | Fix |
|---|---|---|
| `Undefined control sequence` | Typo in a command, or its package isn't loaded | Check the spelling at the marked point; load the package; `texdoc` it |
| `File `x.sty' not found` | Package not installed | `latex-setup` skill: `tlmgr install <pkg>` |
| `Missing $ inserted` | Math-only symbol (`_ ^ \alpha`) in text, or a blank line inside math | Wrap in `$...$`; escape `\_` in text; no blank lines in equations |
| `Missing } inserted` / `Extra }, or forgotten $` | Unbalanced braces or math | Check the line and the ones above it |
| `Runaway argument? ... File ended while scanning use of` | A `{` never closed | Bisect; the cause is above the reported line |
| `Paragraph ended before \x was complete` | Blank line inside a command's argument | Remove the blank line or use a `\long` / `+m` argument |
| `Misplaced alignment tab character &` | `&` in text, or an environment that isn't a tabular | Escape `\&` |
| `Extra alignment tab has been changed to \cr` | More `&` cells than columns | Count the columns in the spec |
| `Misplaced \noalign` | `\hline`/`\midrule` not at the start of a row (after `\\`) | Put `\\` before it; in latexdiff output, see the latex-diff skill |
| `There's no line here to end` | `\\` in vertical mode (after a blank line or at list start) | Remove the `\\`; use a blank line for paragraphs |
| `LaTeX Error: Environment x undefined` | Package missing, or a typo in the environment name | Load the package |
| `\begin{x} on input line N ended by \end{y}` | Mismatched environments | Fix the nesting |
| `Option clash for package x` | Loaded twice with different options | Load once with all options, or `\PassOptionsToPackage` first |
| `Command \x already defined` | `\newcommand` clashes with a package or class | Pick another name, or use `\renewcommand` if overriding is intended |
| `Too many unprocessed floats` | Floats queued faster than they're placed | `\clearpage`, `[htbp]`, fewer floats |
| `Dimension too large` | pgfplots/TikZ data out of range; zero-size image | Rescale data (`restrict y to domain`); check the image |
| `Unknown graphics extension` | Wrong format for the engine (eps under pdflatex) | Convert to pdf/png; don't use `.eps` with pdflatex (or rely on epstopdf) |
| `File ended while scanning` in `.aux` / weird `\@writefile` errors | Corrupt aux from an aborted run | `scripts/build.sh <doc> --clean` |
| `Citation x undefined` | Key not in .bib, bibtex didn't run, or a .bib syntax error | `grep` the key; check the `.blg` for bibtex errors |
| `I found no \citation commands` (bibtex) | No `\cite` yet, or wrong aux | Harmless while drafting |
| `Repeated entry` (bibtex) | Duplicate key in .bib | Remove the duplicate |
| `pdfTeX warning: destination with the same identifier` | Duplicate page or counter anchors (often in front matter) | `\pagenumbering` before the first page; hyperref's `hypertexnames=false` |
| `Package hyperref Warning: Token not allowed in a PDF string` | Math or commands in section titles (bookmarks) | `\texorpdfstring{$\alpha$}{alpha}` |
| `Font shape ... undefined, using ... instead` | Missing bold/italic/smallcaps combination | Usually harmless; `lmodern` fixes most |
| `Overfull \hbox` | A line sticks out into the margin | Reword, `\allowbreak`, `\url{}`, `\sloppy` locally |
| `Label(s) may have changed. Rerun` | Normal on the first runs | latexmk reruns automatically |
| `! Emergency stop` / `*** (job aborted, no legal \end found)` | Fatal earlier error, or missing `\end{document}` | Look at the first error above it |
