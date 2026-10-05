#!/bin/bash

# Applies Win11.xml to the local (session) libvirt daemon that GNOME Boxes uses.
# Run as your normal user - session libvirt, not root.

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
DOMAIN_TEMPLATE="$SCRIPT_DIR/Win11.xml"
DOMAIN="win11"
URI="qemu:///session"
SHARE_DIR="$HOME/Shared"

if [ "$EUID" -eq 0 ]; then
    echo_warn "Run this as your own user - Boxes VMs live in $URI, not the system daemon."
    exit 1
fi

# ========================================
# Host prerequisites
# ========================================

# <portForward> is implemented on top of passt; the older slirp backend has no
# port-forwarding support in libvirt. Without the binary libvirt aborts the
# domain the moment it tries to spawn it, with nothing but
# "Starting external device: passt / shutting down, reason=failed" in the log.
if ! command -v passt >/dev/null 2>&1; then
    echo_info "Installing passt (required for port forwarding)..."
    sudo pacman -S --needed passt
fi
if ! command -v passt >/dev/null 2>&1; then
    echo_warn "passt is still missing - refusing to define a domain that cannot start."
    echo_warn "Install it manually:  sudo pacman -S passt"
    exit 1
fi

# Same story for virtiofsd and the <filesystem> device.
if [ ! -x /usr/lib/virtiofsd ] && [ ! -x /usr/libexec/virtiofsd ]; then
    echo_info "Installing virtiofsd (required for the shared folder)..."
    sudo pacman -S --needed virtiofsd
fi
if [ ! -x /usr/lib/virtiofsd ] && [ ! -x /usr/libexec/virtiofsd ]; then
    echo_warn "virtiofsd is still missing - refusing to define a domain that cannot start."
    echo_warn "Install it manually:  sudo pacman -S virtiofsd"
    exit 1
fi

if [ ! -d "$SHARE_DIR" ]; then
    echo_info "Creating shared folder $SHARE_DIR"
    mkdir -p "$SHARE_DIR"
fi

# ========================================
# Render the template
# ========================================

# Win11.xml is a template: ${HOME} is the only placeholder. uuid and the NIC MAC
# are left out so libvirt keeps the existing ones (or generates them).
DOMAIN_XML="$(mktemp --suffix=.xml)"
trap 'rm -f "$DOMAIN_XML"' EXIT
envsubst '${HOME}' < "$DOMAIN_TEMPLATE" > "$DOMAIN_XML"

# ========================================
# Provisioning media
# ========================================

# Read the target path out of the XML rather than hardcoding it, so the ISO can
# never be built somewhere the domain is not looking. A missing cdrom source is
# silently dropped by startupPolicy="optional", which is very easy to miss.
ISO_PATH="$(python3 - "$DOMAIN_XML" <<'PY'
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
for disk in root.findall("devices/disk"):
    if disk.get("device") == "cdrom":
        print(disk.find("source").get("file"))
        break
PY
)"

if [ -z "$ISO_PATH" ]; then
    echo_warn "No cdrom source found in $DOMAIN_XML - cannot place the provisioning ISO."
    exit 1
fi

echo_info "Building the provisioning ISO..."
"$SCRIPT_DIR/make-provision-iso.sh" "$ISO_PATH"

if [ ! -f "$ISO_PATH" ]; then
    echo_warn "Expected the ISO at $ISO_PATH but it is not there."
    exit 1
fi

# ========================================
# Domain definition
# ========================================
if virsh -c "$URI" domstate "$DOMAIN" >/dev/null 2>&1; then
    STATE="$(virsh -c "$URI" domstate "$DOMAIN")"
    if [ "$STATE" != "shut off" ]; then
        echo_warn "Domain '$DOMAIN' is $STATE. Shut it down first - changes apply at next boot."
        exit 1
    fi

    BACKUP="$SCRIPT_DIR/Win11.xml.bak-$(date +%Y%m%d%H%M%S)"
    echo_info "Backing up the current definition to $(basename "$BACKUP")"
    virsh -c "$URI" dumpxml "$DOMAIN" > "$BACKUP"
fi

echo_info "Validating $DOMAIN_XML..."
virt-xml-validate "$DOMAIN_XML" domain

echo_info "Defining domain '$DOMAIN'..."
virsh -c "$URI" define "$DOMAIN_XML"

cat <<EOF

$(echo_info "Applied.")

  Shared folder   $SHARE_DIR  ->  Z:\\ in the guest
  RDP             127.0.0.1:3389
  WinRM (HTTP)    127.0.0.1:5985
  WinRM (HTTPS)   127.0.0.1:5986

Next: boot the VM, open D:\\ and run Bootstrap.cmd as administrator.
That installs Go, enables RDP/WinRM and mounts the share, then registers a
startup task so every later boot repairs anything missing.

EOF
