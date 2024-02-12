#!/bin/bash

fzfwrap() {
    sel="$(tac "$HOME/.config/mpv/history.log" | awk '!x[$0]++' | fzf --no-preview | awk '{print $NF}')"
    if [ -n "$sel" ]; then
        notify-send "Loading..."
        setsid -f mpv "$sel" || notify-send "Failed to load video"
    fi
}

export -f fzfwrap

alacritty \
    --class float \
    --command bash -c fzfwrap
