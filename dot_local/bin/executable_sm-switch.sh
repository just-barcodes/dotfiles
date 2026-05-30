#!/bin/bash
# sm-switch: pick a live agent session in walker and jump to its window.
set -eu

# ID <TAB> "icon  name" <TAB> last-prompt <TAB> agent
rows=$(sm status --json | jq -r '
  def rank($s): {"waiting":0,"idle":1,"running":2}[$s] // 9;
  def icon($s): {"waiting":"🔴","idle":"🟡","running":"🟢"}[$s] // "⚪";
  [ .[] | select(.Status=="waiting" or .Status=="idle" or .Status=="running") ]
  | sort_by(.LastEventAt) | reverse
  | sort_by(rank(.Status))
  | .[]
  | [ .ID,
      (icon(.Status)+"  "+(.CWD|split("/")|last)),
      ((.LastPrompt // "") | gsub("\\s+";" ") | .[0:80]),
      .Agent ]
  | @tsv
')

# [ -n "$rows" ] || exit 0

idx=$(printf '%s\n' "$rows" | cut -f2- |
    walker -d -i --width 960 -p "session...")

[ -n "$idx" ] || exit 0

id=$(printf '%s\n' "$rows" | sed -n "$((idx + 1))p" | cut -f1)
[ -n "$id" ] || exit 0
exec sm focus "$id"
