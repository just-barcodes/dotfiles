#!/usr/bin/env bash
# Pretty multi-month calendar: 1 previous + current + 3 following.
# Monday as first day of week. Current month gets a slight background.
# Bottom-right shows the current day big.
# Used by waybar clock on-click and tui-launcher.

set -u

# ANSI control sequences
R=$'\033[0m'               # full reset
SR=$'\033[22;23;24;27;39m' # soft reset: keep bg, drop bold/italic/underline/reverse/fg
B=$'\033[1m'
DIM=$'\033[2m'

CYAN=$'\033[38;5;81m'
MAGENTA=$'\033[38;5;213m'
YELLOW=$'\033[38;5;221m'
RED=$'\033[38;5;204m'
GREY=$'\033[38;5;240m'

BG=$'\033[48;2;38;33;58m' # subtle dark indigo
BG_END=$'\033[49m'
INV=$'\033[7m'
INV_END=$'\033[27m'

BAR="│"

today_full=$(date +"%A, %d %B %Y")
time_now=$(date +"%H:%M")
today_day=$(date +"%-d")
today_date=$(date +"%d/%m/%Y")

row2_month=$(date -d "+2 month" +"%-m")
row2_year=$(date -d "+2 month" +"%Y")

# Colorize cal output. BG_MIDDLE=1 wraps the middle month (chars 21-44, 24-wide)
# with a slight background and highlights today within it.
colorize_cal() {
  local bg_middle="$1"
  awk \
    -v TODAY="$today_day" \
    -v BG_MIDDLE="$bg_middle" \
    -v R="$R" -v SR="$SR" -v B="$B" -v DIM="$DIM" \
    -v MAGENTA="$MAGENTA" -v YELLOW="$YELLOW" -v RED="$RED" -v GREY="$GREY" \
    -v BG="$BG" -v BG_END="$BG_END" \
    -v INV="$INV" -v INV_END="$INV_END" \
    -v BAR="$BAR" '
    function colorize_month(s, reset_seq) {
      gsub(/[A-Z][a-z]+ [0-9]{4}/, B MAGENTA "&" reset_seq, s)
      return s
    }
    function colorize_weekday(s, reset_seq,    out) {
      out = s
      gsub(/Sa Su/, RED "Sa Su" YELLOW, out)
      return YELLOW out reset_seq
    }
    function highlight_today(s,    p, re, mat, ipos, ppos) {
      p = sprintf("%2d", TODAY)
      re = "(^|[^0-9])" p "($|[^0-9])"
      if (match(s, re)) {
        mat = substr(s, RSTART, RLENGTH)
        ipos = index(mat, p)
        ppos = RSTART + ipos - 1
        return substr(s, 1, ppos - 1) INV B p INV_END SR substr(s, ppos + length(p))
      }
      return s
    }
    {
      # Three 20-char month columns with 2-char separators between.
      pre  = substr($0, 1, 20)   # month 1
      mid  = substr($0, 23, 20)  # month 2
      post = substr($0, 45)      # month 3 (or empty for row 2)

      is_heading = ($0 ~ /[A-Z][a-z]+ [0-9]{4}/)
      is_weekday = ($0 ~ /Mo Tu We Th Fr Sa Su/)

      mid_reset = BG_MIDDLE ? SR : R

      if (is_heading) {
        pre  = colorize_month(pre, R)
        mid  = colorize_month(mid, mid_reset)
        if (post != "") post = colorize_month(post, R)
      } else if (is_weekday) {
        pre  = colorize_weekday(pre, R)
        mid  = colorize_weekday(mid, mid_reset)
        if (post != "") post = colorize_weekday(post, R)
      } else if (BG_MIDDLE) {
        mid = highlight_today(mid)
      }

      # Vertical separators between months: faint grey bars.
      bar_dim    = DIM GREY BAR R
      bar_dim_bg = DIM GREY BAR SR

      if (BG_MIDDLE) {
        # Layout: pre + space + (bg: bar + mid + bar) + space + post
        out = pre " " BG bar_dim_bg " " mid " " bar_dim_bg BG_END " "
        if (post != "") out = out post
        print out
      } else {
        # Layout: pre + space + bar + space + mid (+ optional bar + post)
        out = pre " " bar_dim " " mid
        if (post != "") {
          out = out " " bar_dim " " post
        } else {
          out = out " "   # pad row-2 lines to a consistent visual width for paste
        }
        print out
      }
    }
  '
}

# Big date display in the bottom-right empty slot.
# figlet "big" font: day digits ~7 high, narrow enough for the slot.
big_date_block() {
  if command -v figlet >/dev/null 2>&1; then
    {
      # figlet emits a trailing blank line on its own, so just one blank between
      # the day art and the labels.
      figlet -w 60 -f standard -- "$today_day" 2>/dev/null || figlet -- "$today_day"
      printf "%s %s\n" "$(date +"%B")" "$(date +"%Y")"
      printf "%s\n" "$(date +"%A")"
    } | awk -v CYAN="$CYAN" -v B="$B" -v R="$R" -v DIM="$DIM" '
      NF == 0 { print; next }
      /^[A-Z][a-z]+ [0-9]{4}$/ { print B CYAN $0 R; next }
      /^[A-Z][a-z]+$/ { print DIM $0 R; next }
      { print CYAN $0 R }
    '
  else
    {
      printf "%s%s%s%s\n" "$B" "$CYAN" "$today_date" "$R"
      echo
      echo
      printf "%s%s %s%s\n" "$DIM" "$(date +"%B")" "$(date +"%Y")" "$R"
      printf "%s%s%s\n" "$DIM" "$(date +"%A")" "$R"
    }
  fi
}

clear
echo
header_line="${CYAN}${B}${today_full}${R}  ${DIM}${time_now}${R}"
printf "  %s\n\n" "$header_line"

# Row 1: prev + current (highlighted) + next
cal -m -3 | colorize_cal 1 | sed 's/^/  /'
echo

# Row 2: +2mo + +3mo, no bg highlight, with big-date pasted to the right.
# Pad the row-2 plain cal output to 44 chars before colorizing so the paste
# alignment is correct (ANSI codes don't change visual width, but they do
# change string length; we want the gap to be consistent visually).
row2=$(cal -m -n 2 "$row2_month" "$row2_year" |
  awk '{printf "%-44s\n", $0}' |
  colorize_cal 0 |
  sed 's/^/  /')
bigdate=$(big_date_block)
paste -d $'\t' <(printf "%s\n" "$row2") <(printf "%s\n" "$bigdate") |
  sed 's/\t/     /'

# echo
read -n 1 -s
