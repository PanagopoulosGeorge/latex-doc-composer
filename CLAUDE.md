# latex-doc-composer

A workspace for drafting, compiling, versioning and diffing LaTeX documents (theses, papers, slides).

## Layout
- `templates/` – `thesis` (custom `thesis.cls` + chapter skeletons), `article`, `beamer`. Each template has `.latexmkrc` and `packages.txt`.
- `docs/<name>/` – the user's documents, created from templates.
- `scripts/` – `setup.sh` (installs TinyTeX + packages), `new-doc.sh`, `build.sh`, `release.sh`, `diff.sh`, `check-tex.sh`, `install-tex.sh` (the Makefile wraps these).
- `.claude/skills/` – how to do things here. Load the matching skill before acting:
  `latex-setup`, `latex-compile`, `latex-diff`, `new-document`, `academic-writing`, `latex-internals`, `doc-review` (user-invoked only).
- `.claude/agents/` – reviewer agents used by `/doc-review`.

## Rules
- Build with `scripts/build.sh`, not raw pdflatex. A change to a document isn't done until it builds without errors or undefined references.
- Never change numbers, results or the meaning of a claim in the user's prose without asking.
- Before large edits to a document, suggest a release (`scripts/release.sh`) so the user can diff afterwards.
- Git tags and commits stay local. Never push unless asked.
- `sudo` and multi-GB installs: show the command and let the user run it.
- Scripts must stay bash 3.2 compatible (macOS). Guard empty arrays under `set -u`, and keep `set -e` from tripping on grep's "no match" exit code.
- After changing a template or script, run `make templates`.
