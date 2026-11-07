#!/usr/bin/env bash
# Build a latexdiff PDF showing changes between two versions of a document.
#
# Usage: scripts/diff.sh <doc-dir> <old> [new]
#   old/new: a git ref (tag, branch, commit, e.g. thesis/v1.0, HEAD~3)
#            or a path to a directory holding another copy of the document.
#   new defaults to the current working tree (including uncommitted edits).
#
# Env:
#   LATEXDIFF_OPTS  extra latexdiff options
#                   (default: --type=UNDERLINE --math-markup=coarse)
#   MAIN            main .tex file if it can't be detected
#
# Output: <doc-dir>/diff/<doc>_<old>_vs_<new>.pdf  (+ the .tex next to it)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

DOC="${1:-}"; OLD="${2:-}"; NEW="${3:-}"
[ -n "$DOC" ] && [ -n "$OLD" ] || die "usage: diff.sh <doc-dir> <old-ref|dir> [new-ref|dir]"
[ -d "$DOC" ] || die "no such directory: $DOC"
command -v latexdiff >/dev/null || die "latexdiff not found (run scripts/check-tex.sh)"
DOC="$(cd "$DOC" && pwd)"
MAINF="$(find_main "$DOC")"
OPTS="${LATEXDIFF_OPTS:---type=UNDERLINE --math-markup=coarse}"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/latexdiff.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# Put version $1 of the document into directory $2.
materialise() {
  local ver="$1" dest="$2" top rel
  mkdir -p "$dest"
  if [ -z "$ver" ]; then
    copy_tree "$DOC" "$dest"
  elif [ -d "$ver" ]; then
    copy_tree "$ver" "$dest"
  else
    top="$(git -C "$DOC" rev-parse --show-toplevel 2>/dev/null)" \
      || die "$DOC is not in a git repo; pass a directory instead of a ref"
    rel="$(cd "$DOC" && git rev-parse --show-prefix)"
    git -C "$top" rev-parse --verify --quiet "$ver^{commit}" >/dev/null \
      || die "unknown git ref: $ver"
    if [ -z "$rel" ]; then
      git -C "$top" archive "$ver" | tar -x -C "$dest"
    else
      mkdir -p "$dest.raw"
      git -C "$top" archive "$ver" -- "$rel" | tar -x -C "$dest.raw"
      [ -d "$dest.raw/$rel" ] || die "$rel does not exist at $ver"
      (cd "$dest.raw/$rel" && tar -cf - .) | (cd "$dest" && tar -xf -)
      rm -rf "$dest.raw"
    fi
  fi
}

info "old: $OLD"; materialise "$OLD" "$TMP/old"
info "new: ${NEW:-working tree}"; materialise "$NEW" "$TMP/new"
[ -f "$TMP/old/$MAINF" ] || die "$MAINF not found in old version ($OLD)"

label() { local s="${1:-working}"; [ -d "$s" ] && s="$(basename "$s")"; s="${s#$(basename "$DOC")/}"; echo "$s" | tr '/ ~^:' '-----'; }
NAME="$(basename "$DOC" | tr " " "-")_$(label "$OLD")_vs_$(label "$NEW")"

info "running latexdiff ($OPTS)"
# --flatten inlines \input/\include so changes inside chapter files show up.
# Parse OPTS like a shell would, so quoted values (--config="A=b c") survive.
eval "OPTARR=($OPTS)"
( cd "$TMP" && latexdiff "${OPTARR[@]}" --flatten "old/$MAINF" "new/$MAINF" ) > "$TMP/new/$NAME.tex" \
  2> "$TMP/latexdiff.err" || { cat "$TMP/latexdiff.err" >&2; die "latexdiff failed"; }

info "compiling diff"
cd "$TMP/new"
set +e
latexmk -pdf -f -interaction=nonstopmode -file-line-error -outdir=build "$NAME.tex" >"$TMP/latexmk.out" 2>&1
set -e
mkdir -p "$DOC/diff"
cp "$NAME.tex" "$DOC/diff/"
if [ -f "build/$NAME.pdf" ]; then
  cp "build/$NAME.pdf" "$DOC/diff/"
  if LC_ALL=C grep -q '^! ' "build/$NAME.log"; then
    echo "warning: the diff compiled with errors (some markup may be off):" >&2
    log_errors "build/$NAME.log" >&2
  fi
  info "ok: $DOC/diff/$NAME.pdf"
else
  echo "DIFF COMPILE FAILED. Errors:" >&2
  log_errors "build/$NAME.log" >&2
  cp "build/$NAME.log" "$DOC/diff/" 2>/dev/null || true
  echo "Try LATEXDIFF_OPTS='--type=UNDERLINE --math-markup=off' or see the latex-diff skill." >&2
  exit 1
fi
