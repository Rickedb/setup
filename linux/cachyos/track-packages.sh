#!/bin/bash

# List explicitly installed packages missing from packages.txt / packages-aur.txt.
# Looks at everything added since the OS installer finished (OS_INSTALL_END),
# so installer-provided packages are ignored. Add what you want to keep to the
# lists by hand; apply.sh installs whatever they contain.

OS_INSTALL_END='2026-10-11T12:00'

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

listed() {
    grep -hvE '^\s*(#|$)' "$REPO/packages.txt" "$REPO/packages-aur.txt" | sort -u
}

# pacman.log timestamps sort lexically, so a string compare is enough
since_install() {
    awk -v end="$OS_INSTALL_END" '
        /\[ALPM\] installed / && substr($1, 2, 16) > end { print $4 }
    ' /var/log/pacman.log | sort -u
}

new="$(comm -12 <(since_install) <(pacman -Qeq | sort) | comm -23 - <(listed))"
gone="$(comm -13 <(pacman -Qq | sort) <(listed))"

if [ -n "$new" ]; then
    echo "Installed but not tracked (add to packages.txt or packages-aur.txt):"
    echo "$new" | sed 's/^/  /'
fi
if [ -n "$gone" ]; then
    echo "Tracked but not installed:"
    echo "$gone" | sed 's/^/  /'
fi
[ -z "$new$gone" ] && echo "Package lists are up to date."
exit 0
