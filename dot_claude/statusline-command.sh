#!/bin/sh
input=$(cat)

data=$(printf '%s' "$input" | jq -r '
  .context_window.used_percentage        // "",
  .context_window.remaining_percentage   // "",
  .context_window.total_input_tokens     // "",
  .context_window.total_output_tokens    // "",
  .rate_limits.five_hour.used_percentage // "",
  .rate_limits.five_hour.resets_at       // ""
')

{
  IFS= read -r used
  IFS= read -r remaining
  IFS= read -r total_in
  IFS= read -r total_out
  IFS= read -r five_hour
  IFS= read -r resets_at
} <<EOF
$data
EOF

if [ -n "$used" ] && [ -n "$remaining" ]; then
  printf "tokens: %d in / %d out | ctx: %.0f%% used / %.0f%% remaining" \
    "$total_in" "$total_out" "$used" "$remaining"
elif [ -n "$total_in" ]; then
  printf "tokens: %d in / %d out" "$total_in" "$total_out"
fi

if [ -n "$five_hour" ]; then
  reset_str=""
  if [ -n "$resets_at" ]; then
    now=$(date +%s)
    mins_left=$(((resets_at - now) / 60))
    reset_at_hhmm=$(date -d "@$resets_at" '+%H:%M')
    if [ "$mins_left" -gt 0 ]; then
      hours_left=$((mins_left / 60))
      mins_part=$((mins_left % 60))
      reset_str=" (resets ${reset_at_hhmm}, in ${hours_left}h${mins_part}m)"
    else
      reset_str=" (resets ${reset_at_hhmm})"
    fi
  fi
  printf " | 5h: %.0f%% used%s" "$five_hour" "$reset_str"
fi
