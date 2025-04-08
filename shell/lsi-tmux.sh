#!/bin/sh

# lazygit single instance in tmux

if [ ! "$TERM" = "tmux-256color" ] || [ -z "$TMUX" ]; then
    lazygit "$@"
else
    killall lazygit
    tmux select-window -t lazygit
    tmux send-keys -t lazygit.1 "cd $PWD && lazygit $*" Enter
fi
