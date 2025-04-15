#!/bin/sh

# neovim single instance in zellij

socket=~/.cache/nvim/server.sock

nvim_start_listen() {
    zellij action go-to-tab-name neovim
    zellij action write-chars "cd $PWD && nvim $* --listen '$socket'"
    zellij action write 13
}

nvim_attach() {
    nvim --server "$socket" --remote-send "<esc><esc>:cd $PWD<cr>" > /dev/null 2>&1
    nvim --server "$socket" --remote "$@" > /dev/null 2>&1
    zellij action go-to-tab-name neovim
}

if [ -z "$ZELLIJ_SESSION_NAME" ]; then
    nvim "$@"
elif echo "$@" | grep vifm.rename; then
    nvim "$@"
else
    if [ -S "$socket" ]; then
        if pgrep --full 'nvim .* --listen'; then
            nvim_attach "$@"
        else
            rm -f "$socket"
            nvim_start_listen "$@"
        fi
    else
        nvim_start_listen "$@"
    fi
fi
