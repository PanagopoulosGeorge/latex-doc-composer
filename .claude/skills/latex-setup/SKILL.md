---
name: latex-setup
description: Check for and install a LaTeX toolchain (pdflatex/xelatex/lualatex, latexmk, latexdiff, BibTeX) and missing LaTeX packages. Use when a build fails with "command not found" or "File `x.sty' not found", when setting up a new machine, or when the user asks to install LaTeX.
---
# LaTeX toolchain setup

## 0. Default: one command
```bash
scripts/setup.sh          # or: make setup
```
- No LaTeX at all: downloads TinyTeX into the user's home folder (`~/Library/TinyTeX` on macOS, `~/.TinyTeX` on Linux). No admin password needed. Then installs every package in `templates/*/packages.txt`, plus latexmk and latexdiff.
  It asks before downloading. **Ask the user first, then pass `--yes`**, since you can't answer the prompt.
- LaTeX already installed: installs only the missing packages. With a system-wide TeX it prints a `sudo tlmgr install ...` line for the user to run.
- The repo scripts find TinyTeX even if it isn't on PATH. `--add-path` also adds it to `~/.zshrc`/`~/.bashrc` for the user's own terminal and editor.
- `scripts/build.sh` **auto-installs** missing packages when the TeX tree is user-writable (TinyTeX), then retries. On a system TeX it prints the install command. `AUTO_INSTALL=0` disables this.

## 1. Diagnose first
```bash
scripts/check-tex.sh                 # tools + packages for all templates
scripts/check-tex.sh docs/<name>     # packages for one document (needs packages.txt)
```
It prints what is missing and the exact `tlmgr install ...` command.

## 2. One missing package (most common)
Error looks like: `! LaTeX Error: File `cleveref.sty' not found.`
1. Find the TeX Live package that contains the file. Usually it has the same name. If not:
   `tlmgr search --global --file /cleveref.sty`
2. Install it. Check whether the TeX tree is writable: `ls -ld "$(kpsewhich -var-value TEXMFROOT)"`
   - writable (TinyTeX, user install): `tlmgr install <pkg>`
   - root-owned (BasicTeX/MacTeX/system TeX Live): `sudo tlmgr install <pkg>`.
     **You cannot type a sudo password.** Give the user the command to run with `! sudo tlmgr install <pkg>`.
   - No sudo available: `tlmgr init-usertree && tlmgr --usermode install <pkg>`
3. Add the `<file> <pkg>` line to the document's `packages.txt` so the next machine gets it.
4. If installing isn't possible, consider swapping the package for one that's present.
   For example, use `\autoref` (in hyperref) instead of `cleveref`.

## 3. No TeX distribution at all
```bash
scripts/install-tex.sh --profile basic     # dry run: prints the commands
scripts/install-tex.sh --profile basic --yes
```
| Profile | Size | Admin? | When |
|---|---|---|---|
| `basic` | ~0.5 GB | yes | Default. BasicTeX (macOS) / texlive base sets (Linux) + only the packages listed in templates |
| `full` | 5–7 GB | yes | Offline work, many unknown packages, or the user doesn't want to deal with missing packages |
| `tinytex` | ~0.3 GB | no | Same as `scripts/setup.sh` (recommended) |

Rules:
- **Always run the dry run first and show the user the commands.** Large downloads and `sudo` need the user's OK.
- Windows: point the user to MiKTeX (installs missing packages on the fly) or the TeX Live installer. The scripts need bash (WSL or Git Bash).
- After installing, a new shell may be needed for PATH (`eval "$(/usr/libexec/path_helper)"` on macOS).
- `latexdiff` ships with TeX Live. It's also on Homebrew (`brew install latexdiff`). It needs Perl, which macOS and Linux already have.
- `biber` is only needed for biblatex documents. The templates use BibTeX + natbib.

## 4. Verify
`scripts/check-tex.sh` must exit 0, then `make templates` builds every template.
