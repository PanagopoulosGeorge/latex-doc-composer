#!/usr/bin/env bash
# Build a document and save it as a numbered version, tagged in git.
#
# Usage: scripts/release.sh <doc-dir> <version> [--allow-dirty] [--no-tag]
#   e.g. scripts/release.sh docs/my-thesis 1.2
# Result:
#   <doc-dir>/releases/<doc>-v<version>.pdf
#   git tag <doc>/v<version>   (local only, never pushed)
# Later: scripts/diff.sh <doc-dir> <doc>/v1.1 <doc>/v1.2
set -euo pipefail
source "$(dirname "$0")/lib.sh"

DOC="${1:-}"; VER="${2:-}"
[ -n "$DOC" ] && [ -n "$VER" ] || die "usage: release.sh <doc-dir> <version> [--allow-dirty] [--no-tag]"
shift 2
ALLOW_DIRTY=0; TAG=1
for a in "$@"; do
  case "$a" in --allow-dirty) ALLOW_DIRTY=1 ;; --no-tag) TAG=0 ;; *) die "unknown option: $a" ;; esac
done
DOC="$(cd "$DOC" && pwd)"
NAME="${DOC_NAME:-$(basename "$DOC")}"
VER="${VER#v}"
TAGNAME="$NAME/v$VER"

INGIT=0; git -C "$DOC" rev-parse --git-dir >/dev/null 2>&1 && INGIT=1
if [ $INGIT = 1 ] && [ $TAG = 1 ]; then
  git -C "$DOC" rev-parse -q --verify "refs/tags/$TAGNAME" >/dev/null && die "tag $TAGNAME already exists"
  if [ $ALLOW_DIRTY = 0 ] && [ -n "$(git -C "$DOC" status --porcelain -- . ':!releases' ':!build' ':!diff')" ]; then
    die "uncommitted changes in $DOC; commit first so the tag matches the PDF (or --allow-dirty)"
  fi
fi

"$(dirname "$0")/build.sh" "$DOC"
MAINF="$(find_main "$DOC")"
OUT="$(out_dir_of "$DOC")"
mkdir -p "$DOC/releases"
DEST="$DOC/releases/$NAME-v$VER.pdf"
cp "$DOC/$OUT/${MAINF%.tex}.pdf" "$DEST"
info "saved $DEST"

if [ $INGIT = 1 ] && [ $TAG = 1 ]; then
  git -C "$DOC" tag -a "$TAGNAME" -m "$NAME version $VER"
  info "tagged $TAGNAME (local; push with: git push origin $TAGNAME)"
fi
