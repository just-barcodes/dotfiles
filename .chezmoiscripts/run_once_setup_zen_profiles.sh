#!/usr/bin/env bash
# Ensure the named zen-browser profiles used by the webapp .desktop entries exist in
# ~/.zen/profiles.ini so the .desktop entries that pass `--profile ~/.zen/<name>`
# launch into the expected profile. Both the directory and the profiles.ini entry
# are required: zen refuses to start with "profile cannot be loaded" if the
# directory is missing, and registering it makes the profile visible in the manager.
#
# Also seeds each profile with uBlock Origin and Vimium.

set -euo pipefail

ZEN_DIR="$HOME/.zen"
INI="$ZEN_DIR/profiles.ini"

PROFILES=(chatgpt youtube tasks)

# "<gecko extension id>=<addons.mozilla.org slug>". The id must match the id in
# the xpi's manifest.json, because zen keys the installed extension off the
# file name.
ADDONS=(
    "uBlock0@raymondhill.net=ublock-origin"
    "{d7742d87-e61d-4b78-b8a1-b469842139fa}=vimium-ff"
)

if ! command -v zen-browser >/dev/null 2>&1; then
    echo "zen-browser not installed; skipping profile setup"
    exit 0
fi

for profile in "${PROFILES[@]}"; do
    mkdir -p "$ZEN_DIR/$profile"
done

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

# Zen ignores xpis dropped into a profile's extensions/ dir unless the profile
# scope is scanned at startup, and even then installs them disabled pending
# approval in about:addons. startupScanScopes=1 and autoDisableScopes=14 (the
# default 15 minus SCOPE_PROFILE) make a dropped xpi install and enable itself,
# while still prompting for sideloads from outside the profile.
ensure_pref() {
    local userjs="$1" name="$2" value="$3"
    if grep -qF "user_pref(\"${name}\"," "$userjs" 2>/dev/null; then
        return
    fi
    printf 'user_pref("%s", %s);\n' "$name" "$value" >>"$userjs"
}

ensure_addon_prefs() {
    local userjs="$ZEN_DIR/$1/user.js"
    ensure_pref "$userjs" extensions.startupScanScopes 1
    ensure_pref "$userjs" extensions.autoDisableScopes 14
}

# Downloads each xpi at most once per run, shared across profiles.
CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT

fetch_addon() {
    local slug="$1" out="$CACHE/$slug.xpi"
    if [ ! -f "$out" ]; then
        curl -fsSL -o "$out" "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi"
    fi
    printf '%s' "$out"
}

# Only seeds a missing addon: an xpi already there may have been updated by zen
# itself, and overwriting it would roll it back.
ensure_addon() {
    local profile="$1" id="$2" slug="$3"
    local dest="$ZEN_DIR/$profile/extensions/${id}.xpi"
    if [ -f "$dest" ]; then
        echo "  ${slug} already present in '${profile}'"
        return
    fi
    local xpi
    if ! xpi=$(fetch_addon "$slug"); then
        echo "  failed to download ${slug}; skipping"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$xpi" "$dest"
    echo "  installed ${slug} into '${profile}'"
}

for profile in "${PROFILES[@]}"; do
    ensure_profile "$profile"
    ensure_addon_prefs "$profile"
    for entry in "${ADDONS[@]}"; do
        ensure_addon "$profile" "${entry%%=*}" "${entry##*=}"
    done
done
