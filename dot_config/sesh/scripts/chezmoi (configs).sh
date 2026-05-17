#!/bin/bash
SESSION="chezmoi (configs)"
DIR=~/.local/share/chezmoi

tmux rename-window -t "$SESSION:" editor
tmux send-keys -t "$SESSION:editor" "cd $DIR && clear && nvim" Enter

tmux new-window -t "$SESSION:" -n shell -c "$DIR"

tmux select-window -t "$SESSION:editor"
