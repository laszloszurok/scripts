#!/bin/sh

# Print current battery level.

if [ -d /sys/class/power_supply/BAT0 ]; then
    device="/sys/class/power_supply/BAT0"
elif [ -d /sys/class/power_supply/BAT1 ]; then
    device="/sys/class/power_supply/BAT1"
fi

get_info() {
    capacity=$(cat "$device"/capacity)
    #status=$(cat "$device"/status)
}

icon=""

get_info

if [ "$capacity" -le 75 ] && [ "$capacity" -gt 50 ]; then
    icon=""
elif [ "$capacity" -le 50 ] && [ "$capacity" -gt 30 ]; then
    icon=""
elif [ "$capacity" -le 30 ] && [ "$capacity" -gt 20 ]; then
    icon=""
elif [ "$capacity" -le 20 ]; then
    icon=""
fi

printf "%s %s\n" "$icon" "$capacity%"
