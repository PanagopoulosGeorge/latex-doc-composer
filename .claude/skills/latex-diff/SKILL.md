---
name: latex-diff
description: Produce a marked-up PDF (latexdiff) showing changes between two versions of a LaTeX document, and manage numbered releases with git tags. Use when the user asks what changed between versions, wants a "changes since review" PDF for a supervisor/reviewer, or wants to release/tag a version.
---
# Versions and diffs

## Releasing a version
```bash
scripts/release.sh docs/<name> 1.2      # builds, saves releases/<name>-v1.2.pdf, tags <name>/v1.2
```
- It refuses to run with uncommitted changes in the document, so the tag always matches the PDF. Commit first, or pass `--allow-dirty` if the user insists.
- Tags are **local**. Never push tags or commits unless the user asks.
- Commit the new `releases/*.pdf` afterwards. Releases are tracked on purpose: they're what was sent to people.
- List versions: `git tag -l '<name>/v*'`

## Making a diff
```bash
scripts/diff.sh docs/<name> <name>/v1.1                 # v1.1 -> current working tree (incl. uncommitted)
scripts/diff.sh docs/<name> <name>/v1.0 <name>/v1.1     # between two releases
scripts/diff.sh docs/<name> HEAD~5                      # any git ref
scripts/diff.sh docs/<name> /path/to/old/copy           # a plain directory (no git needed)
```
The output is `docs/<name>/diff/<name>_<old>_vs_<new>.pdf`, with the generated `.tex` beside it. `diff/` is gitignored and can be regenerated from tags.
It works on any LaTeX folder in any git repo, not only `docs/`. Point it at the folder that holds the main file.

How it works: it extracts both versions to a temp dir and runs `latexdiff --flatten`, which inlines `\input` so edits inside chapter files show up. Then it compiles the result inside a copy of the new version, so its class, figures and .bib are available.

Markup: added text is blue with a wavy underline; deleted text is red with strikethrough.

## Picking the "old" version
- "Changes since the supervisor's review": the tag/commit that was sent for review. Check `git tag`, `git log --oneline -- <doc>`, or the release PDFs.
- If the user only has an old PDF and no source, latexdiff can't help. Say so.

## When the diff fails to compile or looks wrong
Set `LATEXDIFF_OPTS` (it replaces the default `--type=UNDERLINE --math-markup=coarse`):

| Symptom | Try |
|---|---|
| Errors inside equations | `--math-markup=whole` or `--math-markup=off` |
| Errors in tables (`Misplaced \noalign`, `Extra alignment tab`) | `--exclude-textcmd="multicolumn,multirow"`; if the table changed structure, see the note below |
| Errors in `\section{}`/`\caption{}` with markup | `--exclude-textcmd="section,subsection,chapter,caption"` |
| A custom macro breaks | `--append-safecmd="mymacro"` (safe to mark up inside) or `--exclude-safecmd="mymacro"` |
| Citations marked up badly | `--disable-citation-markup` |
| Too noisy (every word underlined) | `--type=CFONT` (colour only) or `--type=CHANGEBAR` (margin bars) |
| Graphics changes | `--graphics-markup=none` (0), `new-only` (1, default), `both` (2) |

Tables or TikZ figures that changed structure can't be marked up word by word. Treat them as whole blocks, so the old one is shown deleted and the new one added:
```bash
LATEXDIFF_OPTS='--type=UNDERLINE --config="PICTUREENV=(?:picture|tikzpicture|tabular|longtable)[\w\d*@]*"'
```

Example: `LATEXDIFF_OPTS="--type=UNDERLINE --math-markup=off --disable-citation-markup" scripts/diff.sh docs/x x/v1.0`

The script uses `latexmk -f`, so a PDF is often produced even with errors. Check the warnings it prints and look at the affected pages before sending.

## Writing a change summary
When the user wants a summary for a reviewer, read the generated `.tex`. Search for `\DIFadd` and `\DIFdel` to find the changes. Group them by chapter and list the substantive ones (new results, changed claims, restructured sections) separately from wording edits.
