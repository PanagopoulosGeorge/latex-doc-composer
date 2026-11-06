#!/usr/bin/env bash
# Create a new document from a template.
# Usage: scripts/new-doc.sh <template> <name> [dest-parent-dir]
#   template: thesis | article | beamer   (any folder under templates/)
#   dest-parent-dir defaults to docs/
set -euo pipefail
source "$(dirname "$0")/lib.sh"

T="${1:-}"; N="${2:-}"; PARENT="${3:-$REPO_ROOT/docs}"
if [ -z "$T" ] || [ -z "$N" ]; then
  echo "usage: new-doc.sh <template> <name> [dest-parent-dir]" >&2
  echo "templates: $(ls "$REPO_ROOT/templates" | tr '\n' ' ')" >&2
  exit 1
fi
SRC="$REPO_ROOT/templates/$T"
[ -d "$SRC" ] || die "no template '$T' (have: $(ls "$REPO_ROOT/templates" | tr '\n' ' '))"
DEST="$PARENT/$N"
[ -e "$DEST" ] && die "$DEST already exists"

mkdir -p "$PARENT"
copy_tree "$SRC" "$DEST"
info "created $DEST from template '$T'"
echo "next:"
[ -f "$DEST/metadata.tex" ] && echo "  1. edit $DEST/metadata.tex (title, author, university...)"
echo "  2. scripts/build.sh $DEST"
