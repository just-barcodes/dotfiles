#!/bin/sh
input=$(cat)

data=$(printf '%s' "$input" | jq -r '
  .model.display_name                    // "",
  .effort.level                          // "",
  .context_window.used_percentage        // "",
  .context_window.remaining_percentage   // "",
  .context_window.total_input_tokens     // "",
  .context_window.total_output_tokens    // "",
  .rate_limits.five_hour.used_percentage // "",
  .rate_limits.five_hour.resets_at       // ""
')

{
  IFS= read -r model
  IFS= read -r effort
  IFS= read -r used
  IFS= read -r remaining
  IFS= read -r total_in
  IFS= read -r total_out
  IFS= read -r five_hour
  IFS= read -r resets_at
} <<EOF
$data
EOF

RST=$(printf '\033[0m')
DIM=$(printf '\033[2m')
CYAN=$(printf '\033[36m')
MAGENTA=$(printf '\033[35m')
SEP=" ${DIM}│${RST} "

# green below 60%, yellow below 80%, bold red at 80%+
pct_color() {
  p=${1%.*}
  if [ "$p" -ge 80 ]; then printf '\033[1;31m'
  elif [ "$p" -ge 60 ]; then printf '\033[33m'
  else printf '\033[32m'; fi
}

fmt_num() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%.1fk", n / 1000
    else printf "%d", n
  }'
}

bar() {
  p=${1%.*}
  filled=$(((p + 5) / 10))
  [ "$filled" -gt 10 ] && filled=10
  i=0
  while [ "$i" -lt 10 ]; do
    if [ "$i" -lt "$filled" ]; then printf '█'; else printf '░'; fi
    i=$((i + 1))
  done
}

out=""
append() {
  if [ -n "$out" ]; then out="${out}${SEP}$1"; else out="$1"; fi
}

if [ -n "$model" ]; then
  seg="$model"
  [ -n "$effort" ] && seg="${seg} ${DIM}${effort}${RST}"
  append "$seg"
fi

if [ -n "$total_in" ]; then
  append "$(printf '%s↑%s%s %s↓%s%s' \
    "$CYAN" "$(fmt_num "$total_in")" "$RST" \
    "$MAGENTA" "$(fmt_num "$total_out")" "$RST")"
fi

if [ -n "$used" ] && [ -n "$remaining" ]; then
  c=$(pct_color "$used")
  append "$(printf '%s%s %.0f%%%s %sctx%s' \
    "$c" "$(bar "$used")" "$used" "$RST" "$DIM" "$RST")"
fi

if [ -n "$five_hour" ]; then
  c=$(pct_color "$five_hour")
  reset_str=""
  if [ -n "$resets_at" ]; then
    now=$(date +%s)
    mins_left=$(((resets_at - now) / 60))
    reset_at_hhmm=$(date -d "@$resets_at" '+%H:%M')
    if [ "$mins_left" -gt 0 ]; then
      reset_str=$(printf ' %s⟳ %s in %dh%02dm%s' \
        "$DIM" "$reset_at_hhmm" $((mins_left / 60)) $((mins_left % 60)) "$RST")
    else
      reset_str=$(printf ' %s⟳ %s%s' "$DIM" "$reset_at_hhmm" "$RST")
    fi
  fi
  append "$(printf '%s%.0f%%%s %s5h%s%s' \
    "$c" "$five_hour" "$RST" "$DIM" "$RST" "$reset_str")"
fi

printf '%s' "$out"