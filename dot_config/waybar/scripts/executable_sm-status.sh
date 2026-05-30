#!/bin/bash
# sm-status — waybar JSON: counts of green(idle)/yellow(waiting)/red(running) sm sessions.
set -eu

command -v sm >/dev/null 2>&1 || {
  echo '{"text":"","tooltip":""}'
  exit 0
}

sm status --json 2>/dev/null | jq -c '
  def icon($s): {"waiting":"🔴","idle":"🟡","running":"🟢"}[$s] // "⚪";
  def chip($hex; $n):
    "<span foreground=\"\($hex)\" size=\"140%\" rise=\"-9000\">●</span>"
    + "<span foreground=\"\($hex)\" rise=\"-7500\"> \($n)</span>";
  "#fa5750" as $cred   |
  "#75b938" as $cgreen |
  "#dbb32d" as $cyellow|
  ( [ .[] | select(.Status=="waiting") ] | length ) as $red    |
  ( [ .[] | select(.Status=="running") ] | length ) as $green  |
  ( [ .[] | select(.Status=="idle")    ] | length ) as $yellow |
  {
    text: "\(chip($cred; $red))  \(chip($cgreen; $green))  \(chip($cyellow; $yellow))",
    class: (if $red > 0 then "waiting" elif $green > 0 then "running" else "idle" end),
    tooltip: (
      [ .[]
        | select(.Status=="waiting" or .Status=="idle" or .Status=="running")
        | icon(.Status) + "  " + (.CWD|split("/")|last) + "  (" + .Agent + ")"
      ] | join("\n")
    )
  }
' 2>/dev/null || echo '{"text":"","tooltip":""}'

