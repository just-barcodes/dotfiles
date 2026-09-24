#!/bin/bash
# sm-switch: pick a live agent session and jump to its window.
#
#   sm-switch.sh         walker dmenu (fallback UI)
#   sm-switch.sh list    rows for the elephant "agents" menu:
#                        id, agent, status, name, title, host, icon (TSV)
#
# host is where the agent process lives, read from its environment like
# `sm focus` does: orca (Orca IDE tab), tmux, terminal (bare window), other.
# icon is a composite SVG (agent logo, then the host icon at the same size),
# generated on demand under ~/.cache/sm-switch/icons because walker shows
# one image per row. Sources: agent-*.svg and host-*.svg in
# ~/.local/share/icons/hicolor/scalable/apps, Orca's own hicolor PNG.
set -eu

icon_src="$HOME/.local/share/icons/hicolor/scalable/apps"
icon_cache="${XDG_CACHE_HOME:-$HOME/.cache}/sm-switch/icons"

# Print the icon for an agent/host pair: a composite path, or an icon-theme
# name when there is no logo for the agent.
icon_for() {
    local agent="$1" host="$2" base="$icon_src/agent-$1.svg" badge=""
    [ -f "$base" ] || { echo utilities-terminal; return; }
    case "$host" in
        tmux|terminal) badge="$icon_src/host-$host.svg" ;;
        orca) badge=/usr/share/icons/hicolor/48x48/apps/stably-orca.png ;;
    esac
    local out="$icon_cache/$agent-$host.svg"
    if [ ! -f "$out" ] || [ "$base" -nt "$out" ] || { [ -n "$badge" ] && [ "$badge" -nt "$out" ]; }; then
        mkdir -p "$icon_cache"
        # Two same-size icons side by side (agent | host) on a 2:1 canvas; the
        # theme's item layout shows it in an 80x40 picture. width/height
        # are set explicitly because gdk-pixbuf rasterizes SVGs at their
        # intrinsic size and walker uploads the result as a texture.
        {
            echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 32" width="256" height="128">'
            printf '<image href="data:image/svg+xml;base64,%s" x="2" y="2" width="28" height="28"/>\n' "$(base64 -w0 "$base")"
            if [ -n "$badge" ] && [ -f "$badge" ]; then
                local mime=image/svg+xml; [ "${badge##*.}" = png ] && mime=image/png
                printf '<image href="data:%s;base64,%s" x="34" y="2" width="28" height="28"/>\n' "$mime" "$(base64 -w0 "$badge")"
            fi
            echo '</svg>'
        } >"$out.tmp" && mv "$out.tmp" "$out"
    fi
    echo "$out"
}

host_of() {
    local env
    env=$(tr '\0' '\n' <"/proc/$1/environ" 2>/dev/null) || { echo other; return; }
    if grep -q '^ORCA_TAB_ID=' <<<"$env"; then echo orca
    elif grep -q '^TMUX_PANE=' <<<"$env"; then echo tmux
    elif grep -qE '^(TERMINAL|TERM_PROGRAM)=' <<<"$env"; then echo terminal
    else echo other; fi
}

# Map each session's CWD to its sesh/zoxide name
sesh_json=$(sesh list -d --json 2>/dev/null || echo '[]')

# waiting first, then idle, then running; newest first within a status
rows=$(sm status --json | jq -r --argjson sesh "${sesh_json:-[]}" '
  def rank($s): {"waiting":0,"idle":1,"running":2}[$s] // 9;
  def cap($n): if (length > $n) then "…" + .[(length - $n + 1):] else . end;
  ( $sesh | map({ key: (.Path | rtrimstr("/")), value: .Name }) | from_entries ) as $names
  | [ .[] | select(.Status=="waiting" or .Status=="idle" or .Status=="running") ]
  | sort_by(.LastEventAt) | reverse
  | sort_by(rank(.Status))
  | .[]
  | [ .ID, .Agent, .Status,
      ( ($names[.CWD | rtrimstr("/")] // (.CWD | split("/") | last)) | cap(40) ),
      ( ((.Title // .LastPrompt) // "") | gsub("\\s+";" ") | .[0:100]
        | if . == "" then "(no title yet)" else . end ),
      .PID ]
  | @tsv
' | while IFS=$'\t' read -r id agent status name title pid; do
    host=$(host_of "$pid")
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$agent" "$status" "$name" "$title" "$host" "$(icon_for "$agent" "$host")"
done)

if [ "${1:-}" = list ]; then
    printf '%s\n' "$rows"
    exit 0
fi

# dmenu renders one label per line, so the visible columns are space-padded
# to align: "status host  agent  name  title" (host is a Nerd Font glyph)
idx=$(printf '%s\n' "$rows" | awk -F'\t' '
    BEGIN { icon["waiting"] = "🔴"; icon["idle"] = "🟡"; icon["running"] = "🟢"
            host["tmux"] = "\uebc8"; host["terminal"] = "\uf120"; host["orca"] = "\uf308"; host["other"] = "?" }
    { id[NR] = $1; a[NR] = $2; s[NR] = $3; n[NR] = $4; t[NR] = $5; h[NR] = $6
      if (length($2) > aw) aw = length($2); if (length($4) > nw) nw = length($4) }
    END { for (k = 1; k <= NR; k++)
            printf "%s %s  %-" aw "s  %-" nw "s  %s\n", (icon[s[k]] ? icon[s[k]] : "⚪"), (host[h[k]] ? host[h[k]] : "?"), a[k], n[k], t[k] }' |
    walker -d -i --width 1280 -p "session...")

[ -n "$idx" ] || exit 0

id=$(printf '%s\n' "$rows" | sed -n "$((idx + 1))p" | cut -f1)
[ -n "$id" ] || exit 0
exec sm focus "$id"
