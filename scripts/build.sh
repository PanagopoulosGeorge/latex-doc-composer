#!/usr/bin/env bash
# Build a LaTeX document with latexmk.
# Usage: scripts/build.sh <doc-dir> [--clean] [--watch]
#   --clean  remove build artifacts first (latexmk -C)
#   --watch  rebuild on every save (latexmk -pvc), Ctrl-C to stop
# If a package is missing and your TeX tree is user-writable (TinyTeX), it is
# installed automatically and the build retried. Disable with AUTO_INSTALL=0.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

DOC="${1:-}"; [ -n "$DOC" ] || die "usage: build.sh <doc-dir> [--clean] [--watch]"
shift
[ -d "$DOC" ] || die "no such directory: $DOC"
DOC="$(cd "$DOC" && pwd)"
MAINF="$(find_main "$DOC")"
cd "$DOC"

EXTRA=()
[ -f .latexmkrc ] || EXTRA=(-pdf -interaction=nonstopmode -file-line-error -synctex=1)
for a in "$@"; do
  case "$a" in
    --clean) info "cleaning"; latexmk -C ${EXTRA[@]+"${EXTRA[@]}"} "$MAINF" >/dev/null 2>&1 || true ;;
    --watch) EXTRA+=(-pvc); [ -n "${LDC_IN_DOCKER:-}" ] && EXTRA+=(-view=none) ;;
    *) die "unknown option: $a" ;;
  esac
done

OUT="$(out_dir_of "$DOC")"
LOG="$OUT/${MAINF%.tex}.log"
PDF="$OUT/${MAINF%.tex}.pdf"

# Missing file named in the log, e.g. "! LaTeX Error: File `cleveref.sty' not found."
missing_file() {
  LC_ALL=C sed -n "s/^! LaTeX Error: File \`\([^']*\)' not found.*/\1/p" "$LOG" 2>/dev/null | head -1 || true
}

# Install the TeX Live package providing file $1. Returns 1 if it can't.
auto_install() {
  local f="$1" pkg
  if [ "${AUTO_INSTALL:-1}" = 0 ] || ! tex_tree_writable; then
    pkg="$(basename "$f")"; pkg="${pkg%.*}"
    echo "Missing LaTeX file: $f. Install it with:" >&2
    if command -v tlmgr >/dev/null; then echo "  sudo tlmgr install $pkg    (if that fails: tlmgr search --global --file /$f)" >&2
    else echo "  your TeX distribution's package manager (MiKTeX console, apt, ...)" >&2; fi
    return 1
  fi
  pkg="$(basename "$f")"; pkg="${pkg%.*}"
  info "missing $f; installing package '$pkg'"
  if tlmgr install "$pkg" 2>&1 | grep -q 'tlmgr itself needs to be updated'; then
    info "updating tlmgr first"
    tlmgr update --self >/dev/null 2>&1
    tlmgr install "$pkg" >/dev/null 2>&1
  fi
  kpsewhich "$f" >/dev/null && return 0
  info "searching TeX Live for $f (can take a minute)"
  pkg="$(tlmgr_pkg_for_file "$f")"
  [ -n "$pkg" ] || { echo "No TeX Live package contains $f" >&2; return 1; }
  info "installing package '$pkg'"
  tlmgr install "$pkg" >/dev/null 2>&1 && kpsewhich "$f" >/dev/null
}

info "building $DOC/$MAINF"
mkdir -p "$OUT"
installed=""
while :; do
  # -g after an auto-install: sources didn't change, so latexmk must be forced to rerun.
  FORCE=(); [ -n "$installed" ] && FORCE=(-g)
  if latexmk ${EXTRA[@]+"${EXTRA[@]}"} ${FORCE[@]+"${FORCE[@]}"} "$MAINF" >"$OUT/.build-output.txt" 2>&1; then
    info "ok: $DOC/$PDF"
    w=$(LC_ALL=C grep -c -E 'Warning' "$LOG" 2>/dev/null || true)
    [ "${w:-0}" -gt 0 ] && info "$w warning(s); see $DOC/$LOG"
    u=$(log_errors "$LOG")
    [ -n "$u" ] && printf '%s\n' "$u" >&2
    [ -n "$installed" ] && info "auto-installed:$installed  (add them to packages.txt)"
    exit 0
  fi
  f="$(missing_file)"
  # Retry after installing a missing package; stop if the same file is still missing.
  if [ -n "$f" ] && case " $installed " in *" $f "*) false ;; *) true ;; esac && auto_install "$f"; then
    installed="$installed $f"
    continue
  fi
  echo "BUILD FAILED. First errors (file:line):" >&2
  log_errors "$LOG" >&2
  echo "Full log: $DOC/$LOG" >&2
  exit 1
done
