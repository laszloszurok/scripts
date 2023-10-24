#!/bin/sh

# This script turns off the screen when the system is idle for
# the configured time, then launches a screen locker and finally
# suspends the OS. Works on tty and in X too.

screen_off_seconds=300  # turn the screen off after this many seconds of inactivity
lock_minutes=5          # time to wait after the screen is turned off before locking the screen
bat_suspend_seconds=600 # time to wait after the screen is turned off before suspending the system when the charger is not connected
ac_suspend_seconds=900  # time to wait after the screen is turned off before suspending the system when the charger is connected

programs_to_check="pacman paru makepkg qbittorrent cp mv cat"
run_xset=true
run_setterm=true

get_bat_device() {
    if [ -f /sys/class/power_supply/BAT0/status ]; then
        bat_dev="/sys/class/power_supply/BAT0/status"
    elif [ -f /sys/class/power_supply/BAT1/status ]; then
        bat_dev="/sys/class/power_supply/BAT1/status"
    else
        bat_dev="undefined"
    fi
}

get_bat_state() {
    if [ "$bat_dev" != "undefined" ]; then
        bat_state=$(cat "$bat_dev")
    else
        bat_state="undefined"
    fi
}

set_wait_time() {
    [ "$bat_state" = "Discharging" ] && time_to_wait="$bat_suspend_seconds" || time_to_wait="$ac_suspend_seconds"
}

get_mon_state() {
    mon_state=$(xset q | grep "Monitor is")
}

get_mon_state_tty() {
    mon_state=$(setterm --term linux --blank < /dev/console)
}

get_audio_device() {
    if [ -f /proc/asound/card0/pcm0p/sub0/status ]; then
        audio_dev="/proc/asound/card0/pcm0p/sub0/status"
    elif [ -f  /proc/asound/card1/pcm0p/sub0/status ]; then
        audio_dev="/proc/asound/card1/pcm0p/sub0/status"
    else
        audio_dev="undefined"
    fi
}

get_audio_state() {
    if [ "$audio_dev" != "undefined" ]; then
        audio_state=$(head -1 < "$audio_dev" | awk '{print $NF}')
    else
        audio_state="undefined"
    fi
}

check_qutebrowser() {
    dpms_state=$(xset q | grep "DPMS is")

    if pactl list sink-inputs | grep "qutebrowser" > /dev/null; then
        if [ "$dpms_state" = "  DPMS is Enabled" ]; then
            xset -dpms
        fi
    else
        if [ "$dpms_state" = "  DPMS is Disabled" ]; then
            xset +dpms
        fi
    fi
}

get_bat_device
get_audio_device

while true; do
    session_type=$(loginctl show-session self | grep "Type" | cut -f2 -d=)
    if [ "$session_type" = "tty" ]; then
        if "$run_setterm"; then
            setterm --term linux --blank 1 > /dev/console # blank the screen after 5 minutes
            run_setterm=false
            run_xset=true
        fi
        get_mon_state_tty
        if [ "$mon_state" != "0" ]; then
            get_bat_state
            set_wait_time

            num="0"
            while [ "$num" -lt "$time_to_wait" ] && [ "$mon_state" != "0" ]; do
                num=$((num+1))
                get_mon_state_tty
                sleep 1
            done
            get_mon_state_tty
            if [ "$mon_state" != "0" ]; then
                if [ -z "$(pidof $(echo $programs_to_check | xargs))" ]; then
                    systemctl suspend 
                fi
            fi
        fi
    elif [ "$session_type" = "x11" ]; then
        if "$run_xset"; then
            xset s off # disable screensaver
            xset dpms "$screen_off_seconds" "$screen_off_seconds" "$screen_off_seconds" # monitor switches off after 300 seconds
            run_xset=false
            run_setterm=true
        fi

        #check_qutebrowser # this is a function call

        get_mon_state

        if [ "$mon_state" = "  Monitor is Off" ]; then
            xautolock -time "$lock_minutes" -locker slock &

            get_bat_state
            set_wait_time

            num="0"
            while [ $num -lt $time_to_wait ] && [ "$mon_state" = "  Monitor is Off" ]; do
                num=$((num+1))
                get_mon_state
                sleep 1
            done

            get_mon_state
            get_audio_state

            if [ "$mon_state" = "  Monitor is Off" ] && [ "$audio_state" != "RUNNING"  ]; then
                if [ -z "$(pidof $(echo $programs_to_check | xargs))" ]; then
                    systemctl suspend 
                fi
            fi
        else
            killall xautolock 2>/dev/null
        fi
    elif [ "$session_type" = "wayland" ]; then
        :
    else
        :
    fi
    sleep 30
done
