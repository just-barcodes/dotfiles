#!/bin/bash
# sm-switch: pick a live agent session in walker and jump to its window.
set -eu

# Map each session's CWD to its sesh/zoxide name
sesh_json=$(sesh list -d --json 2>/dev/null || echo '[]')

# ID <TAB> "icon  agent  name  title"; dmenu renders one label per line, so
# the visible columns are space-padded to align
rows=$(sm status --json | jq -r --argjson sesh "${sesh_json:-[]}" '
  def rank($s): {"waiting":0,"idle":1,"running":2}[$s] // 9;
  def icon($s): {"waiting":"🔴","idle":"🟡","running":"🟢"}[$s] // "⚪";
  def cap($n): if (length > $n) then "…" + .[(length - $n + 1):] else . end;
  def pad($w): . + (if ($w - length) > 0 then " " * ($w - length) else "" end);
  ( $sesh | map({ key: (.Path | rtrimstr("/")), value: .Name }) | from_entries ) as $names
  | [ .[] | select(.Status=="waiting" or .Status=="idle" or .Status=="running") ]
  | sort_by(.LastEventAt) | reverse
  | sort_by(rank(.Status))
  | map({
      id: .ID,
      icon: icon(.Status),
      agent: .Agent,
      name: ( ($names[.CWD | rtrimstr("/")] // (.CWD | split("/") | last)) | cap(40) ),
      title: ( ((.Title // .LastPrompt) // "") | gsub("\\s+";" ") | .[0:100]
               | if . == "" then "(no title yet)" else . end )
    })
  | (map(.agent | length) | max // 0) as $aw
  | (map(.name  | length) | max // 0) as $nw
  | .[]
  | [ .id,
      ( .icon + "  " + (.agent | pad($aw)) + "  " + (.name | pad($nw)) + "  " + .title ) ]
  | @tsv
')

# [ -n "$rows" ] || exit 0

idx=$(printf '%s\n' "$rows" | cut -f2 |
    walker -d -i --width 1280 -p "session...")

[ -n "$idx" ] || exit 0

id=$(printf '%s\n' "$rows" | sed -n "$((idx + 1))p" | cut -f1)
[ -n "$id" ] || exit 0
exec sm focus "$id"
