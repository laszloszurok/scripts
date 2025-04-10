#!/bin/sh

# neovim single instance in zellij

socket=~/.cache/nvim/server.sock

if [ -z "$ZELLIJ_SESSION_NAME" ]; then
    nvim "$@"
elif echo "$@" | grep vifm.rename; then
    nvim "$@"
else
    if [ -S "$socket" ]; then
        nvim --server "$socket" --remote-send "<esc><esc>:cd $PWD<cr>" > /dev/null 2>&1
        nvim --server "$socket" --remote "$@" > /dev/null 2>&1
        zellij action go-to-tab-name neovim
    else
        zellij action go-to-tab-name neovim
        zellij action write-chars "cd $PWD && nvim $* --listen '$socket'"
        zellij action write 13
    fi
fi
