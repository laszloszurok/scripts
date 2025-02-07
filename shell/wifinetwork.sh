#!/bin/sh

# WiFi network status bar indicator.
# Uses nmcli to get connection information.

icon=""

notify() {
    dunstify --appname="wifi" --replace=1 "$1" "$2" --timeout="$3"
}

data_path=~/.local/share/wifi_state
current_state=$(cat $data_path)

#ssid=$(nmcli -get-values name,device connection show --active | grep wlp1s0 | cut -d : -f1)
ssid=$(iw dev wlp1s0 link | grep 'SSID: .*' | cut -d ' ' -f 2-)
signal=$(awk 'NR==3 {printf("%.0f%%",$3*10/7)}' /proc/net/wireless)
[ -z "$signal" ] && signal="0%"

airplane_mode=$(rfkill | grep wlan | grep --word-regexp blocked)

title="Checking connection"
sub="Please wait..."
timeout=7000

if [ -n "$airplane_mode" ]; then # check for airplane mode
    icon=""
    title="Airplane mode"
    sub="No signal"
    status="airplane"
elif [ -z "$ssid" ]; then # checking if we are connected to a wifi network
    icon=""
    title="Connection lost"
    sub="No WiFi network"
    status="no-network"
else
    title="$ssid"
    if ping -c 2 -W 1 8.8.8.8 > /dev/null 2>&1; then
        icon=""
        sub="Online, signal: $signal"
        status="online"
        if nmcli -get-values type connection show --active | grep wireguard > /dev/null 2>&1; then
            icon="" 
            sub="Online, signal: $signal\nWireguard tunnel active"
            status="wireguard"
        fi
        # if ! host -W 3 google.com > /dev/null 2>&1; then
        #     sub="Online, signal: $signal\nDNS resolution timeout"
        #     status="dns-timeout"
        # fi
    else
        icon=""
        sub="Offline, signal: $signal"
        status="offline"
    fi
fi

if [ "$current_state" != "$status" ]; then
    notify "$title" "$sub" "$timeout"
    printf "%s\n" "$status" > $data_path
fi

printf "%s\n" "{\"text\":\"$signal\", \"alt\":\"$status\"}"
