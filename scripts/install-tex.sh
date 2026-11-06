#!/usr/bin/env bash
# Install a LaTeX toolchain (engines, latexmk, latexdiff, BibTeX) plus the
# packages the templates need.
#
# Usage: scripts/install-tex.sh [--profile basic|full|tinytex] [--yes]
#   basic   (default) small distribution + only the needed packages
#           macOS: BasicTeX (~100 MB)   Linux: apt/dnf texlive base sets
#   full    everything (~5-7 GB). macOS: MacTeX (no GUI). Linux: texlive-full
#   tinytex no admin rights needed; installs into your home directory
#           (same as scripts/setup.sh, the recommended default)
#   --yes   actually run the commands. Without it, prints them (dry run).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PROFILE=basic; RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="$2"; shift ;;
    --yes|-y) RUN=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac; shift
done

# tlmgr packages needed by the scripts and all templates
PKGS="latexmk latexdiff $(cat "$REPO_ROOT"/templates/*/packages.txt | awk '!/^#/ && NF {print $2}' | sort -u | tr '\n' ' ')"

CMDS=()
OS="$(uname -s)"
case "$PROFILE:$OS" in
  full:Darwin)    CMDS+=("brew install --cask mactex-no-gui") ;;
  basic:Darwin)   CMDS+=("brew install --cask basictex"
                         "eval \"\$(/usr/libexec/path_helper)\""
                         "sudo tlmgr update --self"
                         "sudo tlmgr install $PKGS") ;;
  full:Linux|basic:Linux)
    if command -v apt-get >/dev/null; then
      if [ "$PROFILE" = full ]; then CMDS+=("sudo apt-get update" "sudo apt-get install -y texlive-full")
      else CMDS+=("sudo apt-get update"
                  "sudo apt-get install -y texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-bibtex-extra texlive-science texlive-pictures latexmk latexdiff biber")
      fi
    elif command -v dnf >/dev/null; then
      if [ "$PROFILE" = full ]; then CMDS+=("sudo dnf install -y texlive-scheme-full")
      else CMDS+=("sudo dnf install -y texlive-scheme-medium latexmk texlive-latexdiff")
      fi
    else
      die "unsupported Linux package manager; use --profile tinytex"
    fi ;;
  tinytex:*)
    CMDS+=("$REPO_ROOT/scripts/setup.sh --yes") ;;
  *) die "unsupported profile/OS: $PROFILE on $OS (Windows: install MiKTeX or TeX Live manually)" ;;
esac

if command -v pdflatex >/dev/null && [ "$PROFILE" != full ]; then
  info "a TeX distribution is already installed: $(tex --version | head -1)"
  info "to add only missing packages, run scripts/check-tex.sh and use the tlmgr command it prints"
fi

if [ $RUN = 0 ]; then
  echo "Dry run. Commands for profile '$PROFILE' on $OS:"
  printf '  %s\n' "${CMDS[@]}"
  echo "Re-run with --yes to execute (some need sudo)."
  exit 0
fi
for c in "${CMDS[@]}"; do info "$c"; eval "$c"; done
info "done. Open a new terminal, then run scripts/check-tex.sh"
