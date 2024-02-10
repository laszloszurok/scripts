#!/bin/sh

# to be able to suspend the system after a session gets locked
# with physlock the following polkit rules are needed in the
# file /etc/polkit-1/rules.d/10-power.rules:
# polkit.addRule(function(action, subject) {
# if ((action.id == "org.freedesktop.login1.suspend" ||
#     action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
#     action.id == "org.freedesktop.login1.hibernate" ||
#     action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
#     action.id == "org.freedesktop.login1.reboot" ||
#     action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
#     action.id == "org.freedesktop.login1.power-off" ||
#     action.id == "org.freedesktop.login1.power-off-multiple-sessions") &&
#     (subject.isInGroup("power"))) {
#     return polkit.Result.YES;
# }
# });
# and the user has to be in the power gorup

# shellcheck disable=SC2016
lockcmd='[ -z "$(pidof physlock)" ] && physlock -s -m -p "Session locked" -d'

# run wayland stuff

systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
fi

waybar &

swaybg --image ~/pictures/wallpapers/planets-2.jpg &

# swayidle -w \
#     timeout 420 'hyprctl dispatch dpms off' \
#     timeout 600 "$lockcmd" \
#     timeout 2100 'systemctl suspend' \
#     resume 'hyprctl dispatch dpms on' \
#     before-sleep "$lockcmd" &

swayidle -w \
    timeout 600 "$lockcmd" \
    timeout 2100 'systemctl suspend' \
    before-sleep "$lockcmd" &

battery-low.sh &
kanshi &
tvnotipy &
