#!/bin/bash
# sm-switch: pick a live agent session in walker and jump to its window.
set -eu

# ID <TAB> "icon  agent  path  prompt"; dmenu renders one label per line, so
# the visible columns are space-padded to align
rows=$(sm status --json | jq -r --arg home "$HOME" '
  def rank($s): {"waiting":0,"idle":1,"running":2}[$s] // 9;
  def icon($s): {"waiting":"🔴","idle":"🟡","running":"🟢"}[$s] // "⚪";
  def shortpath($p): if ($p|startswith($home)) then "~"+$p[($home|length):] else $p end;
  def cap($n): if (length > $n) then "…" + .[(length - $n + 1):] else . end;
  def pad($w): . + (if ($w - length) > 0 then " " * ($w - length) else "" end);
  [ .[] | select(.Status=="waiting" or .Status=="idle" or .Status=="running") ]
  | sort_by(.LastEventAt) | reverse
  | sort_by(rank(.Status))
  | map({
      id: .ID,
      icon: icon(.Status),
      agent: .Agent,
      path: (shortpath(.CWD) | cap(40)),
      prompt: ( (.LastPrompt // "") | gsub("\\s+";" ") | .[0:100]
                | if . == "" then "(no prompt yet)" else . end )
    })
  | (map(.agent | length) | max // 0) as $aw
  | (map(.path  | length) | max // 0) as $pw
  | .[]
  | [ .id,
      ( .icon + "  " + (.agent | pad($aw)) + "  " + (.path | pad($pw)) + "  " + .prompt ) ]
  | @tsv
')

# [ -n "$rows" ] || exit 0

idx=$(printf '%s\n' "$rows" | cut -f2 |
    walker -d -i --width 1280 -p "session...")

[ -n "$idx" ] || exit 0

id=$(printf '%s\n' "$rows" | sed -n "$((idx + 1))p" | cut -f1)
[ -n "$id" ] || exit 0
exec sm focus "$id"
