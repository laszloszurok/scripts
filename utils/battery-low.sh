#!/bin/sh

# Send notification when the battery level falls below 20%.
# When the battery level falls below 10% show a countdown
# notification, then suspend the system.

# create a pid file to make sure only one instance of this script is running
pid_dir=/run/user/1000/user-scripts
mkdir -p "$pid_dir"
pid_file="$pid_dir/battery-low.sh.pid"

if [ ! -f "$pid_file" ]; then
    echo $$ > "$pid_file"
    trap 'rm -f -- "$pid_file"; trap - EXIT; exit' EXIT INT HUP

    if [ -d /sys/class/power_supply/BAT0 ]; then
        device="/sys/class/power_supply/BAT0"
    elif [ -d /sys/class/power_supply/BAT1 ]; then
        device="/sys/class/power_supply/BAT1"
    fi

    get_status() {
        status=$(cat "$device/status")
    }
    get_capacity() {
        capacity=$(cat "$device/capacity")
    }

    while true; do
        get_status
        if [ "$status" != "Charging" ]; then
            get_capacity
            if [ "$capacity" -le 10 ]; then
                ( sleep 2m; systemctl suspend ) &
                suspend_pid=$!
                sec=120
                while [ "$sec" -gt 0 ]; do
                    get_status
                    if [ "$status" = "Charging" ]; then
                        kill $suspend_pid
                        notify-send " " \
                            --replace-id=48918 \
                            --expire-time=1
                        notified=true
                        break
                    fi
                    countdown_pct=$(echo "scale=2; $sec/120*100" | bc)
                    notify-send "Low battery level" \
                        "Battery level is below 10%. Suspending in 2 minutes\!" \
                        --replace-id=48918 \
                        --urgency=critical \
                        --hint "int:value:$countdown_pct"
                    sec=$((sec-1))
                    sleep 1
                done
            elif [ "$capacity" -le 20 ]; then
                notify-send \
                    "Low battery level" \
                    "Battery level is below 20%. Connect the the charger." \
                    --replace-id=48918 \
                    --urgency=critical
            else
                :
            fi
        fi
        if [ "$notified" = "true" ]; then
            notify-send " " \
                --replace-id=48918 \
                --expire-time=1
            notified=false
        fi
        sleep 30
    done
else
    printf "%s\n" "$(basename "$0") is already running"
fi
