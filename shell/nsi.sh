#!/bin/sh

# neovim single instance

socket=~/.cache/nvim/server.sock

if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    nvim "$@"
elif echo "$@" | grep vifm.rename; then
    nvim "$@"
else
    if [ -S "$socket" ]; then
        nvim --server "$socket" --remote-send "<esc><esc>:cd $PWD<cr>" > /dev/null 2>&1
        nvim --server "$socket" --remote "$@" > /dev/null 2>&1
        if [ -n "$WAYLAND_DISPLAY" ]; then
            if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
                hyprctl dispatch focuswindow "address:$(hyprctl clients -j | jq -r '.[] | select(.class=="neovim-single-instance").address')"
            fi
        fi
    else
        setsid -f kitty --class neovim-single-instance nvim "$@" --listen "$socket" > /dev/null 2>&1
    fi
fi
