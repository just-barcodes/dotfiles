#!/bin/bash
# Shared sesh startup: an "editor" window running nvim in $DIR, plus a "shell"
# window. Args: <session-name> <dir>
SESSION="$1"
DIR="$2"

tmux rename-window -t "$SESSION:" editor
tmux send-keys -t "$SESSION:editor" "cd '$DIR' && clear && nvim" Enter

tmux new-window -t "$SESSION:" -n shell -c "$DIR"

tmux select-window -t "$SESSION:editor"