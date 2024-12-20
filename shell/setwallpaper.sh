#!/bin/sh

# If this script is given an image, it sets that image as the wallpaper.
# Otherwise it sets the wallpaper to the last image that was used.

wallpaper_path=$HOME/.config/wallpaper

if [ -f "$1" ]; then
    notify-send -i "$wallpaper_path" "Changing wallpaper..."
    ln -sf "$(readlink -f "$1")" "$wallpaper_path"
fi

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    xwallpaper --zoom "$wallpaper_path"
elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    killall hyprpaper
    setsid -f hyprpaper > /dev/null 2>&1
fi
