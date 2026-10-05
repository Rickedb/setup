#!/usr/bin/env bash
# Restores VS Code profiles from this folder: config files + extensions.
set -euo pipefail
cd "$(dirname "$0")"

CODE="${CODE:-code-insiders}"
case "$CODE" in
  code) USER_DIR="$HOME/.config/Code/User" ;;
  *)    USER_DIR="$HOME/.config/Code - Insiders/User" ;;
esac

install_exts() { # <extensions.txt> [profile name]
  while read -r id; do
    [ -n "$id" ] || continue
    if [ -n "${2:-}" ]; then "$CODE" --profile "$2" --install-extension "$id" --force
    else "$CODE" --install-extension "$id" --force; fi
  done < "$1"
}

profile_location() { # <profile name> -> folder under profiles/, empty if missing
  awk -v n="$1" '
    /"location"/ { loc = $0; sub(/^[^:]*: *"/, "", loc); sub(/".*/, "", loc) }
    /"name"/     { if (index($0, "\"" n "\"")) { print loc; exit } }
  ' "$USER_DIR/globalStorage/storage.json" 2>/dev/null || true
}

# Display name per profile folder, as shown in VS Code.
declare -A NAMES=(
  [csharp]="C#"
  [vue]="Vue"
  [go]="Go"
  [finance]="Finance"
  [unity]="Unity"
)

mkdir -p "$USER_DIR"
if [ $# -eq 0 ]; then
  cp -r default/. "$USER_DIR/" && rm -f "$USER_DIR/extensions.txt"
  install_exts default/extensions.txt
fi

for dir in profiles/*/; do
  key=$(basename "$dir")
  [ $# -eq 0 ] || [ "$1" = "$key" ] || continue
  name="${NAMES[$key]}"
  loc=$(profile_location "$name")
  if [ -z "$loc" ]; then
    echo "profile \"$name\" not found, creating it"
    "$CODE" --profile "$name" --list-extensions > /dev/null
    loc=$(profile_location "$name")
    [ -n "$loc" ] || { echo "could not create profile \"$name\"" >&2; exit 1; }
  fi
  install_exts "$dir/extensions.txt" "$name"
  target="$USER_DIR/profiles/$loc"
  mkdir -p "$target"
  cp -r "$dir"/. "$target/" && rm -f "$target/extensions.txt"
  echo "applied $name -> $target"
done
