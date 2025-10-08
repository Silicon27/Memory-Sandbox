#!/usr/bin/env bash
# install.sh -- install GAO_BIN_DIR environment variable pointing to src/cprocess/Gao/binaries
# Place at project root and run: ./install.sh
set -euo pipefail

# ---------------- helpers ----------------
timestamp() { date +"%Y%m%dT%H%M%S"; }

# Escape a string for single-quoted shell literal:
# Produces a single-quoted string safe for POSIX shells even if the value contains single quotes.
escape_for_single_quotes() {
  # usage: escape_for_single_quotes "some'value" -> prints the escaped single-quoted form
  local s="$1"
  # replace each ' with '\'' and then surround with single quotes
  printf "'%s'" "$(printf "%s" "$s" | sed "s/'/'\\\\''/g")"
}

# ---------------- compute GAO_BIN_DIR ----------------
# Resolve script directory robustly (works when script is symlinked)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# project-root-relative path to binaries
GAO_BIN_REL="src/cprocess/Gao/binaries"
GAO_BIN_DIR="$SCRIPT_DIR/$GAO_BIN_REL"

if [ ! -d "$GAO_BIN_DIR" ]; then
  echo "ERROR: Gao binaries directory not found at:"
  echo "  $GAO_BIN_DIR"
  echo "Make sure you run this script from the project root or that the repository layout is intact."
  exit 1
fi

# canonicalize path: prefer realpath/readlink; fallback to python
if command -v realpath >/dev/null 2>&1; then
  GAO_BIN_DIR="$(realpath "$GAO_BIN_DIR")"
elif readlink -f / >/dev/null 2>&1; then
  GAO_BIN_DIR="$(readlink -f "$GAO_BIN_DIR")"
else
  # fallback: use python
  GAO_BIN_DIR="$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$GAO_BIN_DIR")"
fi

# ---------------- find candidate rc file ----------------
USER_SHELL="$(basename "${SHELL:-}")"
RC_CANDIDATES=""
case "$USER_SHELL" in
  zsh)
    RC_CANDIDATES="$HOME/.zshrc:$HOME/.zprofile:$HOME/.zshenv"
    ;;
  bash)
    RC_CANDIDATES="$HOME/.bash_profile:$HOME/.bashrc:$HOME/.profile"
    ;;
  fish)
    RC_CANDIDATES="$HOME/.config/fish/config.fish"
    ;;
  *)
    RC_CANDIDATES="$HOME/.profile:$HOME/.bashrc:$HOME/.zshrc:$HOME/.config/fish/config.fish"
    ;;
esac

target_rc=""
IFS=':' read -r -a rc_array <<< "$RC_CANDIDATES"
for p in "${rc_array[@]}"; do
  if [ -f "$p" ]; then
    target_rc="$p"
    break
  fi
done

if [ -z "$target_rc" ]; then
  echo "No standard shell rc file found for shell '$USER_SHELL'."
  printf "Please enter the full path to the rc file you want to update (or press Enter to create ~/.profile): "
  read -r userfile
  if [ -z "$userfile" ]; then
    userfile="$HOME/.profile"
  fi
  if [ ! -e "$userfile" ]; then
    printf "File '%s' does not exist. Create it? [y/N]: " "$userfile"
    read -r create_reply
    if [[ "$create_reply" =~ ^[Yy]$ ]]; then
      mkdir -p "$(dirname "$userfile")" || true
      : > "$userfile"
      target_rc="$userfile"
      echo "Created $target_rc"
    else
      echo "Aborting. Re-run when you have an rc file available."
      exit 1
    fi
  else
    target_rc="$userfile"
  fi
fi

# ---------------- backup ----------------
bak="${target_rc}.bak.$(timestamp)"
cp -- "$target_rc" "$bak"
echo "Backed up $target_rc -> $bak"

# ---------------- write/update env var ----------------
VAR_NAME="GAO_BIN_DIR"
VAR_VALUE="$GAO_BIN_DIR"
marker_start="# >>> install.sh added: ${VAR_NAME} (do not edit between markers)"
marker_end="# <<< install.sh end: ${VAR_NAME}"

# detect fish by file name
is_fish=0
if [[ "$target_rc" == *"config.fish" ]] || [[ "$USER_SHELL" == "fish" ]]; then
  is_fish=1
fi

if [ "$is_fish" -eq 1 ]; then
  # fish syntax: set -x VAR value
  # If an existing set -x for VAR exists, replace it; otherwise append.
  if grep -E -q "^\s*set\s+-x\s+${VAR_NAME}\b" "$target_rc"; then
    awk -v var="$VAR_NAME" -v val="$VAR_VALUE" '
      BEGIN { repl = "set -x " var " \"" val "\"" }
      {
        if ($0 ~ ("^\\s*set\\s+-x\\s+"var"\\b")) {
          if (!replaced) { print repl; replaced=1; next }
          else next
        }
        print $0
      }
      END { if (!replaced) print repl }
    ' "$target_rc" > "${target_rc}.tmp" && mv "${target_rc}.tmp" "$target_rc"
    echo "Updated existing fish 'set -x' for $VAR_NAME in $target_rc"
  else
    printf "%s\nset -x %s \"%s\"\n%s\n" "$marker_start" "$VAR_NAME" "$VAR_VALUE" "$marker_end" >> "$target_rc"
    echo "Appended fish 'set -x' for $VAR_NAME to $target_rc"
  fi
else
  # POSIX shells: export VAR="value"
  # If an assignment or export for VAR exists, replace; else append a new marker block.
  if grep -E -q "^\s*export\s+${VAR_NAME}=" "$target_rc" || grep -E -q "^\s*${VAR_NAME}=" "$target_rc"; then
    # replace existing lines (assignment or export) with marker block, preserving idempotence
    awk -v var="$VAR_NAME" -v val="$VAR_VALUE" -v s="$marker_start" -v e="$marker_end" '
    BEGIN{ repl = s "\nexport " var "=\"" val "\"\n" e }
    {
      if ($0 ~ ("^\\s*export\\s+"var"=") || $0 ~ ("^\\s*"var"=")) {
        if (!replaced) { print repl; replaced=1; next }
        else next
      }
      print $0
    }
    END { if (!replaced) print repl }
    ' "$target_rc" > "${target_rc}.tmp" && mv "${target_rc}.tmp" "$target_rc"
    echo "Updated existing assignment/export of $VAR_NAME in $target_rc"
  else
    printf "%s\nexport %s=\"%s\"\n%s\n" "$marker_start" "$VAR_NAME" "$VAR_VALUE" "$marker_end" >> "$target_rc"
    echo "Appended export $VAR_NAME to $target_rc"
  fi
fi

# ---------------- final instructions ----------------
echo
echo "SUCCESS: $VAR_NAME set to:"
echo "  $VAR_VALUE"
echo
echo "The variable was persisted in: $target_rc"
echo "Backup saved at: $bak"
echo
echo "To apply the change in the current shell, run:"
echo "  source \"$target_rc\""
echo "or open a new terminal session."
