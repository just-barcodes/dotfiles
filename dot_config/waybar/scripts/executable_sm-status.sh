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
  "#fa5750" as $color_red    |
  "#75b938" as $color_green  |
  "#dbb32d" as $color_yellow |
  ( [ .[] | select(.Status=="waiting") ] | length ) as $n_waiting |
  ( [ .[] | select(.Status=="running") ] | length ) as $n_running |
  ( [ .[] | select(.Status=="idle")    ] | length ) as $n_idle    |
  {
    text: "\(chip($color_red; $n_waiting))  \(chip($color_green; $n_running))  \(chip($color_yellow; $n_idle))",
    class: (if $n_waiting > 0 then "waiting" elif $n_running > 0 then "running" else "idle" end),
    tooltip: (
      [ .[]
        | select(.Status=="waiting" or .Status=="idle" or .Status=="running")
        | icon(.Status) + "  " + (.CWD|split("/")|last) + "  (" + .Agent + ")"
      ] | join("\n")
    )
  }
' 2>/dev/null || echo '{"text":"","tooltip":""}'

