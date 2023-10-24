#!/bin/sh

#lockcmd="swaylock -f"
lockcmd="gtklock \
    --style ~/.config/gtklock/config.css \
    --start-hidden \
    --idle-hide \
    --idle-timeout 10 \
    --daemonize"

# run wayland stuff

systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
fi

waybar &

swaybg --image ~/pictures/wallpapers/planets-2.jpg &

swayidle -w \
    timeout 420 'hyprctl dispatch dpms off' \
    timeout 600 "$lockcmd" \
    timeout 2100 'systemctl suspend' \
    resume 'hyprctl dispatch dpms on' \
    before-sleep "$lockcmd" &

battery-low.sh &
kanshi &
