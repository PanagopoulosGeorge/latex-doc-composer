---
name: new-document
description: Start a new LaTeX document (thesis, article/paper, beamer slides) from the repo templates and fill in its metadata. Use when the user wants to start writing a new thesis, paper, report or presentation.
---
# Starting a document

```bash
scripts/new-doc.sh <template> <name>      # -> docs/<name>/
```
| Template | Use for | Main parts |
|---|---|---|
| `thesis` | MSc/PhD thesis, long report | `thesis.cls`, `metadata.tex`, `chapters/01..06`, `frontmatter/`, `appendix/` |
| `article` | paper, short report | single `main.tex`, IMRaD sections |
| `beamer` | talk, defence slides | 16:9 deck with sentence-style frame titles |

After creating:
1. **thesis**: fill `metadata.tex` (title lines, author, degree, university, supervisor, committee). Every key is listed in `thesis.cls` under `\setmeta`. A logo is optional: put `figures/logo.pdf|png|jpg` in place, or change the `thesislogo` key.
2. Class options: `\documentclass[greek]{thesis}` adds Greek; `oneside` gives single-sided printing.
3. Build it once (`scripts/build.sh docs/<name>`) before editing, to confirm the toolchain works.
4. Commit, then `scripts/release.sh docs/<name> 0.1` to create a starting point for future diffs.

Conventions in the templates:
- `\todo{...}` prints a red note. Before a release, check with `grep -rn '\\todo{' docs/<name>` and resolve every hit.
- The comments at the top of each chapter explain what the chapter must do. They're for the author and never print. Keep them while drafting.
- Labels use prefixes: `ch:`, `sec:`, `fig:`, `tab:`, `alg:`, `eq:`, `app:`. Refer with `\autoref{...}`.
- Recurring terms and symbols go in `macros.tex` as macros.
- If the document needs a new package, add it to `packages.txt` (`file.sty  tlmgr-name`).

For a venue-specific paper (IEEE, ACM, Springer LNCS...), start from `article`, then swap `\documentclass` for the venue's class and drop `geometry`. Venue classes set their own margins.
