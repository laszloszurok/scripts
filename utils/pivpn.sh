#!/bin/sh

if [ "$1" = "up" ]; then
    if sudo -A wg-quick up wg0; then
        ip=$(curl ipinfo.io/ip || curl ifconfig.me)
        notify-send "Wireguard tunnel actived" "IP address: $ip"
    else
        notify-send "Something went wrong"
    fi
elif [ "$1" = "down" ]; then
    if sudo -A wg-quick down wg0; then
        ip=$(curl ipinfo.io/ip || curl ifconfig.me)
        notify-send "Wireguard tunnel deactived" "IP address: $ip"
    else
        notify-send "Something went wrong"
    fi
fi

kill -35 "$(pidof dwmblocks)"
