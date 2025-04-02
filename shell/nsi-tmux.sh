#!/bin/sh

# neovim single instance in tmux

socket=~/.cache/nvim/server.sock

if [ ! "$TERM" = "tmux-256color" ] || [ -z "$TMUX" ]; then
    nvim "$@"
elif echo "$@" | grep vifm.rename; then
    nvim "$@"
else
    if [ -S "$socket" ]; then
        nvim --server "$socket" --remote-send "<esc><esc>:cd $PWD<cr>" > /dev/null 2>&1
        nvim --server "$socket" --remote "$@" > /dev/null 2>&1
        tmux select-window -t neovim
    else
        tmux send-keys -t neovim.0 "cd $PWD && nvim $* --listen '$socket'" Enter
        tmux select-window -t neovim
    fi
fi
