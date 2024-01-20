#!/bin/sh

if pidof "alacritty"; then
    setsid -f alacritty msg create-window --working-directory="$HOME" "$@"
else
    setsid -f alacritty "$@"
fi
