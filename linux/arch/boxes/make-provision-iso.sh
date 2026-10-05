#!/bin/bash

# Builds the provisioning CD attached to the win11 domain.
# The guest gets it as D:\ and runs Bootstrap.cmd from there once.

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/provision"
ISO_PATH="${1:-$HOME/.local/share/gnome-boxes/win11-provision.iso}"

if [ ! -d "$SOURCE_DIR" ]; then
    echo_warn "Missing $SOURCE_DIR"
    exit 1
fi

if ! command -v xorrisofs >/dev/null 2>&1 && ! command -v mkisofs >/dev/null 2>&1; then
    echo_warn "Neither xorrisofs nor mkisofs found. Install libisoburn or cdrtools."
    exit 1
fi

# Windows is far happier with CRLF in .cmd files, so stage a converted copy
# instead of shipping the repo's LF originals.
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT

echo_info "Staging provisioning files..."
for src in "$SOURCE_DIR"/*; do
    name="$(basename "$src")"
    case "$name" in
        *.cmd|*.ps1|*.txt)
            sed 's/\r$//; s/$/\r/' "$src" > "$STAGE_DIR/$name"
            ;;
        *)
            cp -r "$src" "$STAGE_DIR/$name"
            ;;
    esac
    echo "  + $name"
done

mkdir -p "$(dirname "$ISO_PATH")"

echo_info "Building $ISO_PATH"
if command -v xorrisofs >/dev/null 2>&1; then
    xorrisofs -quiet -J -joliet-long -r -V PROVISION -o "$ISO_PATH" "$STAGE_DIR"
else
    mkisofs -quiet -J -joliet-long -r -V PROVISION -o "$ISO_PATH" "$STAGE_DIR"
fi

echo_info "Done: $(du -h "$ISO_PATH" | cut -f1) at $ISO_PATH"
echo_info "The guest mounts this as D:\\ - run D:\\Bootstrap.cmd as administrator."
