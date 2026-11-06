#!/usr/bin/env bash
# One-command setup: make sure a LaTeX toolchain and every package the
# templates need are installed. Safe to re-run.
#
# Usage: scripts/setup.sh [--yes] [--add-path]
#   --yes       don't ask before downloading TinyTeX
#   --add-path  also add TinyTeX to PATH in your shell profile (~/.zshrc or ~/.bashrc)
#
# - No LaTeX found      -> installs TinyTeX in your home folder (~250 MB,
#                          no admin password), then the needed packages.
# - LaTeX found         -> installs only missing packages (tlmgr). If your TeX
#                          is a system install (MacTeX/BasicTeX/apt), that needs
#                          sudo: the script prints the command for you to run.
# Override the TinyTeX location with TINYTEX_HOME=/path.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

YES=0; ADD_PATH=0
for a in "$@"; do
  case "$a" in
    --yes|-y) YES=1 ;;
    --add-path) ADD_PATH=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) die "unknown option: $a" ;;
  esac
done

confirm() {
  [ $YES = 1 ] && return 0
  [ -t 0 ] || die "$1 -- re-run with --yes to confirm"
  printf '%s [y/N] ' "$1"; read -r ans; case "$ans" in y|Y|yes) return 0 ;; *) return 1 ;; esac
}

install_tinytex() {
  local root os arch url ext tmp
  root="$(tinytex_root)"
  os="$(uname -s)"; arch="$(uname -m)"
  case "$os:$arch" in
    Darwin:*)              url_suffix="darwin.tgz" ;;
    Linux:x86_64)          url_suffix="linux-x86_64.tar.xz" ;;
    Linux:aarch64|Linux:arm64) url_suffix="linux-arm64.tar.xz" ;;
    *) die "no prebuilt TinyTeX for $os $arch. Install TeX Live manually: https://tug.org/texlive/" ;;
  esac
  url="https://github.com/rstudio/tinytex-releases/releases/download/daily/TinyTeX-1-$url_suffix"
  confirm "No LaTeX found. Download TinyTeX (~120 MB download, ~250 MB on disk) into $root?" \
    || die "cancelled. Alternatives: scripts/install-tex.sh --profile basic|full"
  [ -e "$root" ] && die "$root already exists but has no working tlmgr; remove it and re-run"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/tinytex.XXXXXX")"
  info "downloading $url"
  download "$url" "$tmp/tinytex.$url_suffix"
  mkdir -p "$(dirname "$root")"
  info "extracting to $root"
  tar -xf "$tmp/tinytex.$url_suffix" -C "$tmp"
  [ -d "$tmp/.TinyTeX" ] && mv "$tmp/.TinyTeX" "$root" || mv "$tmp/TinyTeX" "$root"
  rm -rf "$tmp"
  PATH="$(tinytex_bin):$PATH"; export PATH
  info "TinyTeX installed: $(tex --version | head -1)"
}

# 0. Basic tools (preinstalled on macOS; minimal Linux may lack some)
miss=()
for t in git make perl tar; do command -v "$t" >/dev/null || miss+=("$t"); done
command -v curl >/dev/null || command -v wget >/dev/null || miss+=(curl)
if [ "$(uname -s)" = Linux ] && ! command -v pdflatex >/dev/null; then
  command -v xz >/dev/null || miss+=("$(command -v apt-get >/dev/null && echo xz-utils || echo xz)")
fi
if [ ${#miss[@]} -gt 0 ]; then
  echo "Missing basic tools: ${miss[*]}. Install them with:" >&2
  echo "  $(pkg_hint "${miss[@]}")" >&2
  exit 1
fi

# 1. A TeX distribution
if ! command -v pdflatex >/dev/null || ! command -v tlmgr >/dev/null; then
  if command -v pdflatex >/dev/null; then
    info "pdflatex found but no tlmgr (MiKTeX or a distro TeX?). Install missing packages with your package manager."
    exec "$(dirname "$0")/check-tex.sh"
  fi
  install_tinytex
else
  info "LaTeX found: $(tex --version | head -1) ($(kpsewhich -var-value TEXMFROOT))"
fi

# 2. Missing tools and packages
need=()
for t in latexmk latexdiff; do command -v "$t" >/dev/null || need+=("$t"); done
for f in "$REPO_ROOT"/templates/*/packages.txt; do
  while read -r file pkg _; do
    case "$file" in ''|\#*) continue ;; esac
    kpsewhich "$file" >/dev/null 2>&1 || need+=("$pkg")
  done < "$f"
done
if [ ${#need[@]} -gt 0 ]; then
  pkgs="$(printf '%s\n' "${need[@]}" | sort -u | tr '\n' ' ')"
  if tex_tree_writable; then
    info "installing: $pkgs"
    # shellcheck disable=SC2086
    tlmgr install $pkgs
  else
    echo "Your TeX installation is system-wide, so installing packages needs admin rights."
    echo "Run this (it will ask for your password), then re-run scripts/setup.sh:"
    echo "  sudo tlmgr install $pkgs"
    exit 1
  fi
fi

# 3. PATH for the user's own terminal (scripts in this repo find TinyTeX anyway)
if tb="$(tinytex_bin)"; then
  line="export PATH=\"$tb:\$PATH\""
  case "${SHELL:-}" in */zsh) rc="$HOME/.zshrc" ;; *) rc="$HOME/.bashrc" ;; esac
  if [ $ADD_PATH = 1 ]; then
    grep -qxF "$line" "$rc" 2>/dev/null || { echo "$line  # TinyTeX" >> "$rc"; info "added TinyTeX to PATH in $rc (open a new terminal)"; }
  elif ! grep -qF "$tb" "$rc" 2>/dev/null; then
    info "to use pdflatex/latexmk directly in your terminal or editor, run: scripts/setup.sh --add-path"
  fi
fi

"$(dirname "$0")/check-tex.sh" >/dev/null && info "setup complete. Try: make new T=thesis N=my-thesis && make build D=docs/my-thesis"
