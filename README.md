# latex-doc-composer

A ready-made workspace for writing a **thesis, paper or presentation in LaTeX**. It takes care of the tedious parts:

- **Templates** that compile out of the box: a full thesis (title page, declaration, chapters), an article, and slides.
- **One-command setup**: installs LaTeX for you if you don't have it. No admin password needed.
- **One-command build**: compiles the PDF and tells you the file and line of any error.
- **Versions**: save numbered PDFs (v1.0, v1.1, ...) each time you send a draft to your supervisor.
- **Change PDFs**: generate a PDF with additions in blue and deletions in red between any two versions. Useful for "here's what I changed after your comments".
- **Writing guidance**: each thesis chapter starts with notes on what it should contain and the usual mistakes. Optional AI assistant support (Claude Code) is included.

You don't need to know how LaTeX is installed or compiled to use it.

---

## 1. Setup (once per computer)

You need **macOS or Linux** with `git`. On **Windows**, use WSL (Windows Subsystem for Linux) and follow the Linux steps. See [Windows](#windows).

```bash
git clone <repo-url> latex-doc-composer
cd latex-doc-composer
make setup
```

`make setup` checks your computer and:
- **If LaTeX isn't installed**: downloads [TinyTeX](https://yihui.org/tinytex/), a small TeX Live distribution (~120 MB download). It installs into your home folder, so no administrator password is needed. Then it adds every package the templates use.
- **If you already have LaTeX** (MacTeX, BasicTeX, TeX Live): it installs only the missing packages. If your LaTeX is a system-wide install, it prints one `sudo tlmgr install ...` line for you to run.

Re-running it is safe. When it finishes, it says `setup complete`.

To also use `pdflatex` directly in your own terminal or editor (VS Code, TeXstudio), run `scripts/setup.sh --add-path` and open a new terminal. The scripts in this repo don't need this.

**Prefer a full LaTeX installation?** `scripts/install-tex.sh --profile full` shows the commands for MacTeX or `texlive-full` (5–7 GB, needs admin).

---

## 2. Start your document

```bash
make new T=thesis N=my-thesis        # T can be: thesis, article, beamer
```
This creates the folder `docs/my-thesis/`. Open `docs/my-thesis/metadata.tex` and fill in your title, name, degree, university, supervisor and committee. They're used on the title, copyright, signature and declaration pages. To show your university's logo, put it at `docs/my-thesis/figures/logo.pdf` (or `.png`/`.jpg`).

The thesis template looks like this:
```
docs/my-thesis/
├── main.tex               ← the master file; lists the chapters in order
├── metadata.tex           ← title, author, university, committee
├── macros.tex             ← your own shortcuts and symbols
├── references.bib         ← bibliography (BibTeX)
├── chapters/
│   ├── 01-introduction.tex
│   ├── 02-background.tex
│   ├── 03-related-work.tex
│   ├── 04-method.tex
│   ├── 05-evaluation.tex
│   └── 06-conclusions.tex
├── frontmatter/           ← abstract, acknowledgements, acronyms
├── appendix/
└── figures/
```
Each chapter file starts with a comment block (it doesn't appear in the PDF) explaining what the chapter should do. Rename, add or remove chapters freely; just update the `\input{...}` lines in `main.tex`.

Class options go in the first line of `main.tex`: `\documentclass[greek]{thesis}` adds Greek language support, and `oneside` gives single-sided printing.

---

## 3. Write and compile

```bash
make build D=docs/my-thesis          # → docs/my-thesis/build/main.pdf
make watch D=docs/my-thesis          # rebuilds automatically every time you save (Ctrl-C to stop)
```
If something is wrong, you get the file and line of the first error, e.g. `./chapters/04-method.tex:37: Undefined control sequence.` Fix that first; later errors are usually caused by it.

If you use a package you don't have yet, the build **downloads it automatically** (with the TinyTeX setup) and tries again.

Tips:
- `\todo{check this number}` prints a red note in the PDF, so unfinished bits are hard to miss.
- Refer to things with `\autoref{ch:intro}` → "Chapter 1", `\autoref{tab:main-results}` → "Table 5.1".
- Cite with `\cite{key}`, where `key` comes from `references.bib`.

---

## 4. Save versions and see what changed

Versions use **git**, which keeps the history of your files. Save your work with a commit, then mark a version whenever you send a draft to someone:

```bash
git add -A
git commit -m "Draft for supervisor"
make release D=docs/my-thesis V=1.0
```
This saves `docs/my-thesis/releases/my-thesis-v1.0.pdf` (the exact PDF you sent) and labels this point in history as `my-thesis/v1.0`.

After you've worked on the feedback:
```bash
make diff D=docs/my-thesis OLD=my-thesis/v1.0                       # v1.0 vs. your current text
make diff D=docs/my-thesis OLD=my-thesis/v1.0 NEW=my-thesis/v1.1    # between two versions
```
The result is in `docs/my-thesis/diff/`: your document with **added text in blue** and **deleted text in red, crossed out**. You can send it straight to your supervisor.

List your versions with `git tag`.

---

## 5. Already have a LaTeX project?

The build and diff commands work on any LaTeX folder, not only those created here:
```bash
scripts/build.sh ~/path/to/old-thesis
scripts/diff.sh  ~/path/to/old-thesis <old-commit-or-tag>
```
If your main file isn't `main.tex`, they read it from your `.latexmkrc`, or you can say `MAIN=thesis.tex scripts/build.sh ...`.

---

## 6. With an AI assistant (optional)

The repo includes instructions ("skills") for [Claude Code](https://claude.com/claude-code). Open it in this folder and ask in plain language:

- "Set up LaTeX on my machine"
- "Start a new thesis called my-thesis"
- "Compile my thesis and fix the errors"
- "Make a PDF of what changed since v1.0 and summarise the changes for my supervisor"
- "Review my introduction: do the contributions match the results in chapter 5?"
- `/doc-review docs/my-thesis`: a committee-style review by several independent reviewer agents, written to `REVIEW.md`. It doesn't edit your text.

The writing guidance the assistant follows is readable on its own too: [academic-writing](.claude/skills/academic-writing/SKILL.md), plus a [pre-submission checklist](.claude/skills/academic-writing/references/checklist.md).

---

## Command reference

| Command | What it does |
|---|---|
| `make setup` | Install LaTeX (if needed) and all required packages |
| `make check` | Show what's installed and what's missing |
| `make new T=<template> N=<name>` | Create `docs/<name>` from `thesis`, `article` or `beamer` |
| `make build D=<folder>` | Compile to `<folder>/build/main.pdf` |
| `make watch D=<folder>` | Recompile on every save |
| `make clean D=<folder>` | Delete build files and rebuild from scratch (fixes most "weird" errors) |
| `make release D=<folder> V=<version>` | Save a numbered PDF and mark the version in git |
| `make diff D=<folder> OLD=<version> [NEW=<version>]` | Red/blue PDF of changes |

All of these are short wrappers around the scripts in `scripts/`; the comment at the top of each script lists its options.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `make: command not found` | macOS: `xcode-select --install`. Ubuntu: `sudo apt install make` |
| `latexmk: command not found` after setup | Run `make setup` again from inside the repo; or `scripts/setup.sh --add-path` and open a new terminal |
| `File 'x.sty' not found` | With TinyTeX it installs automatically. Otherwise run the `sudo tlmgr install ...` line printed |
| Strange errors after an aborted build | `make clean D=<folder>`, then build again |
| `??` instead of a reference number | A `\label` is missing or misspelled. Labels go **after** `\caption` |
| `[?]` instead of a citation | The key isn't in `references.bib` (check the spelling) |
| The diff PDF fails or looks odd around tables or equations | See the options in [latex-diff](.claude/skills/latex-diff/SKILL.md) |
| `release` says "uncommitted changes" | `git add -A && git commit -m "..."` first, so the version matches the PDF |

### Windows
Install WSL (`wsl --install` in PowerShell as administrator, then restart), open the Ubuntu terminal, and follow the Linux steps. You can edit files from Windows with VS Code and its WSL extension.
If you'd rather stay in native Windows, install [MiKTeX](https://miktex.org/), which downloads packages on demand, and compile `main.tex` from your editor. You'll lose the version and diff commands, which need bash.

---

## Repository layout
```
templates/   thesis · article · beamer  (copied by `make new`)
docs/        your documents
scripts/     setup, build, release, diff, check
.claude/     AI assistant skills and reviewer agents (optional)
```

## Credits
The thesis class (`templates/thesis/thesis.cls`) is adapted from the thesis class by Michiel de Dood (2000–2002). `losymbol.sty` and `losnotations.sty` are by Gerry van Dooren (1992). Their original headers are kept in the files.
