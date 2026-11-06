#!/usr/bin/env bash
# Check that the LaTeX toolchain (and optionally a document's packages) is installed.
# Usage: scripts/check-tex.sh [doc-or-template-dir ...]
# Each dir may have a packages.txt: "<file.sty|cls>  <tlmgr-package>" per line.
# Exit 0 if everything is present, 1 otherwise. Prints the install command for
# anything missing.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

missing_tools=(); missing_pkgs=()
ok()   { printf '  %-12s %s\n' "$1" "$2"; }

echo "Tools:"
for t in pdflatex xelatex lualatex latexmk latexdiff bibtex biber makeindex tlmgr; do
  if p=$(command -v "$t"); then ok "$t" "$p"
  else
    case "$t" in
      biber|xelatex|lualatex) ok "$t" "(optional) not found" ;;
      *) ok "$t" "MISSING"; missing_tools+=("$t") ;;
    esac
  fi
done
if command -v tex >/dev/null; then
  echo "Distribution: $(tex --version | head -1)"
  command -v tlmgr >/dev/null && echo "TEXMFROOT: $(kpsewhich -var-value TEXMFROOT)"
fi

DIRS=("$@")
[ ${#DIRS[@]} -eq 0 ] && for d in "$REPO_ROOT"/templates/*/; do DIRS+=("$d"); done
for d in "${DIRS[@]}"; do
  f="$d/packages.txt"; [ -f "$f" ] || continue
  n_before=${#missing_pkgs[@]}
  echo "Packages for $(basename "$d"):"
  while read -r file pkg _; do
    case "$file" in ''|\#*) continue ;; esac
    if ! kpsewhich "$file" >/dev/null 2>&1; then
      ok "$file" "MISSING (tlmgr: $pkg)"; missing_pkgs+=("$pkg")
    fi
  done < "$f"
  [ ${#missing_pkgs[@]} -eq "$n_before" ] && echo "  all present"
done

if [ ${#missing_tools[@]} -eq 0 ] && [ ${#missing_pkgs[@]} -eq 0 ]; then
  echo "All required tools and packages are installed."; exit 0
fi
echo
[ ${#missing_tools[@]} -gt 0 ] && echo "Missing tools: ${missing_tools[*]}  -> scripts/install-tex.sh"
if [ ${#missing_pkgs[@]} -gt 0 ]; then
  u=$(printf '%s\n' "${missing_pkgs[@]}" | sort -u | tr '\n' ' ')
  echo "Missing packages. Install with:"
  if [ -w "$(kpsewhich -var-value TEXMFROOT 2>/dev/null || echo /nonexistent)" ]; then
    echo "  tlmgr install $u"
  else
    echo "  sudo tlmgr install $u"
  fi
fi
exit 1
