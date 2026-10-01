#!/bin/sh

# neovim single instance in zellij

socket=/tmp/nvim-server.sock

nvim_start_listen() {
    zellij action go-to-tab-name neovim
    zellij run --in-place --close-replaced-pane -- nvim $* --listen "$socket"
}

nvim_attach() {
    nvim --embed --server "$socket" --remote-send "<esc><esc>:cd $PWD<cr>"
    nvim --embed --server "$socket" --remote "$@"
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
fi > /dev/null 2>&1
