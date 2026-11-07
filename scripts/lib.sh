# Shared helpers for latex-doc-composer scripts. Source, don't run.
# Bash 3.2 compatible (macOS default shell).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*" >&2; }

# Copy a document folder without build output or git data (no rsync needed).
copy_tree() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  (cd "$src" && tar -cf - --exclude=build --exclude=diff --exclude=releases --exclude=.git .) \
    | (cd "$dest" && tar -xf -)
}

# Download URL $1 to file $2 with curl or wget.
download() {
  if command -v curl >/dev/null; then curl -L -f --retry 3 -o "$2" "$1"
  elif command -v wget >/dev/null; then wget -q --tries=3 -O "$2" "$1"
  else die "need curl or wget to download $1"; fi
}

# Print the command that installs packages $* with the system package manager.
pkg_hint() {
  if command -v apt-get >/dev/null; then echo "sudo apt-get install -y $*"
  elif command -v dnf >/dev/null; then echo "sudo dnf install -y $*"
  elif command -v pacman >/dev/null; then echo "sudo pacman -S --needed $*"
  elif command -v zypper >/dev/null; then echo "sudo zypper install -y $*"
  elif command -v brew >/dev/null; then echo "brew install $*"
  else echo "install: $*"; fi
}

# ---- TinyTeX (user-level TeX installed by scripts/setup.sh) ---------------
# Where setup.sh installs TinyTeX. Override with TINYTEX_HOME.
tinytex_root() {
  if [ -n "${TINYTEX_HOME:-}" ]; then echo "$TINYTEX_HOME"
  elif [ "$(uname -s)" = Darwin ]; then echo "$HOME/Library/TinyTeX"
  else echo "$HOME/.TinyTeX"; fi
}
# Put TinyTeX's bin dir on PATH if it exists, so scripts work even when the
# user's shell profile doesn't have it.
tinytex_bin() {
  local d
  for d in "$(tinytex_root)"/bin/*; do
    [ -x "$d/tlmgr" ] && { echo "$d"; return 0; }
  done
  return 1
}
if _tb="$(tinytex_bin)"; then
  case ":$PATH:" in *":$_tb:"*) ;; *) PATH="$_tb:$PATH"; export PATH ;; esac
fi
unset _tb

# True if tlmgr can install packages without sudo.
tex_tree_writable() {
  local r
  command -v tlmgr >/dev/null || return 1
  r="$(kpsewhich -var-value TEXMFROOT 2>/dev/null)" || return 1
  [ -n "$r" ] && [ -w "$r" ] && [ -w "$r/tlpkg" ]
}

# Print the TeX Live package that contains file $1 (e.g. cleveref.sty).
tlmgr_pkg_for_file() {
  tlmgr search --global --file "/$1" 2>/dev/null | awk -v f="/$1" '
    /^[^ \t].*:$/ { pkg = substr($0, 1, length($0) - 1); next }
    /^[ \t]/ { if (length($0) >= length(f) && substr($0, length($0) - length(f) + 1) == f) { print pkg; exit } }'
}

# Print the main .tex file name (relative to the document dir).
# Order: $MAIN env var, @default_files in .latexmkrc, main.tex, the only
# top-level .tex file containing \documentclass.
find_main() {
  local dir="$1" f cands
  if [ -n "${MAIN:-}" ]; then echo "$MAIN"; return; fi
  for rc in "$dir/.latexmkrc" "$dir/latexmkrc"; do
    if [ -f "$rc" ]; then
      f=$(sed -n "s/^[[:space:]]*@default_files[^']*'\([^']*\)'.*/\1/p" "$rc" | head -1)
      if [ -n "$f" ] && [ -f "$dir/$f" ]; then echo "$f"; return; fi
    fi
  done
  if [ -f "$dir/main.tex" ]; then echo "main.tex"; return; fi
  cands=$(cd "$dir" && grep -l '^[[:space:]]*\\documentclass' *.tex 2>/dev/null)
  if [ "$(printf '%s\n' "$cands" | grep -c .)" = "1" ]; then echo "$cands"; return; fi
  die "cannot find the main .tex file in $dir (set MAIN=file.tex)"
}

# Print error lines from a LaTeX log in file:line form, plus LaTeX "!" errors.
log_errors() {
  local log="$1"
  [ -f "$log" ] || return 0
  LC_ALL=C grep -n -E '^[^ ]+\.(tex|sty|cls|def|ldf):[0-9]+:|^! ' "$log" | head -20 || true
  LC_ALL=C grep -E 'Citation .* undefined|Reference .* undefined' "$log" | LC_ALL=C sort -u | head -10
  return 0
}

# Output dir latexmk uses for a document (honours $out_dir in .latexmkrc).
out_dir_of() {
  local dir="$1" od
  od=$(sed -n "s/^[[:space:]]*\$out_dir[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" "$dir/.latexmkrc" 2>/dev/null | head -1)
  echo "${od:-.}"
}
