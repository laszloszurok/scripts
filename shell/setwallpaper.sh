#!/bin/sh

# Create a link at ~/.config/wallpaper to an image file
# passed as the first argument. Then ~/.config/wallpaper
# can be used to set the wallpeper to that image.

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
