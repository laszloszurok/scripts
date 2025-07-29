#!/bin/sh

# neovim single instance in tmux

socket=~/.cache/nvim/server.sock

if [ ! "$TERM" = "tmux-256color" ] || [ -z "$TMUX" ]; then
    nvim "$@"
elif echo "$@" | grep vifm.rename; then
    nvim "$@"
else
    if [ -S "$socket" ]; then
        nvim --embed --server "$socket" --remote-send "<esc><esc>:cd $PWD<cr>"
        nvim --embed --server "$socket" --remote "$@"
        tmux select-window -t neovim
    else
        tmux send-keys -t neovim.1 "cd $PWD && nvim $* --listen '$socket'" Enter
        tmux select-window -t neovim
    fi
fi > /dev/null 2>&1
