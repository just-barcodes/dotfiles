#!/usr/bin/env bash
# Ensure named zen-browser profiles "chatgpt" and "youtube" exist in
# ~/.zen/profiles.ini so the .desktop entries that pass `--profile ~/.zen/<name>`
# launch into the expected profile. The profile *directories* are created
# automatically by zen on first launch; this script only registers the
# profiles.ini metadata so they show up in zen's profile manager.

set -euo pipefail

ZEN_DIR="$HOME/.zen"
INI="$ZEN_DIR/profiles.ini"

if ! command -v zen-browser >/dev/null 2>&1; then
    echo "zen-browser not installed; skipping profile setup"
    exit 0
fi

mkdir -p "$ZEN_DIR/chatgpt" "$ZEN_DIR/youtube"

# If profiles.ini doesn't exist yet, seed with a minimal header.
if [ ! -f "$INI" ]; then
    cat >"$INI" <<'EOF'
[General]
StartWithLastProfile=1
Version=2
EOF
fi

# Add a named profile entry if it's not already present. Uses the next free
# [ProfileN] index so existing profiles aren't disturbed.
ensure_profile() {
    local name="$1"
    if grep -qE "^Name=${name}$" "$INI"; then
        echo "zen profile '${name}' already registered"
        return
    fi
    local next
    next=$(grep -oE '^\[Profile[0-9]+\]' "$INI" \
        | grep -oE '[0-9]+' \
        | sort -n \
        | tail -1)
    next=$((${next:--1} + 1))
    {
        printf '\n[Profile%d]\n' "$next"
        printf 'Name=%s\n' "$name"
        printf 'IsRelative=1\n'
        printf 'Path=%s\n' "$name"
    } >>"$INI"
    echo "registered zen profile '${name}' as [Profile${next}]"
}

ensure_profile chatgpt
ensure_profile youtube