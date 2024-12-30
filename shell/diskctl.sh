#!/bin/sh

# This script provides an interactive menu to mount/unmount/eject, etc.
# block devices. It uses the output of lsblk to get device names and
# udisksctl to execute a selected action.

save_term() { tput smcup; }
restore_term() { tput rmcup; }
clear_screen() { tput clear; }

# $1 : prompt str, $2 : list to choose from
selection_prompt() {
    printf "%s\n\n" "$1"
    printf "%s\n\n" "$2"
    printf "Number: "
    read -r num
    printf "\n"
    clear_screen
}

# $1: list to choose from
select_from() {
    i=1
    printf "%s" "$1" | while IFS= read -r line; do
        if [ "$i" = "$num" ]; then
            printf "%s\n" "$line" | awk '{ print $3 }'
            return
        fi
        i=$((i+1))
    done
    exit 1
}

trap 'restore_term' EXIT
save_term

while true; do
    info=$(lsblk --list)
    devices=$(printf "%s\n" "$info" | grep "disk" | nl -w1 -s' - ')
    partitions=$(printf "%s\n" "$info" | grep "part")
    mounted=$(printf "%s\n" "$partitions" | grep -v "[[:space:]]*part[[:space:]]*$" | nl -w1 -s' - ')
    unmounted=$(printf "%s\n" "$partitions" | grep "[[:space:]]*part[[:space:]]*$" | nl -w1 -s' - ')

    printf "l - list devices\nm - mount a partition\nu - unmount a partition\ne - eject a device\np - power off a device\nq - quit\n\n"
    printf "Select an option: "
    read -r key

    clear_screen

    case $key in
        "l")
            lsblk ;;
        "m") 
            selection_prompt "Select a partition to mount:" "$unmounted"
            selected=$(select_from "$unmounted") \
                && udisksctl mount -b "/dev/$selected" \
                || printf "Selection failed\n"
            ;;
        "u") 
            selection_prompt "Select a partition to unmount:" "$mounted"
            selected=$(select_from "$mounted") \
                && udisksctl unmount -b "/dev/$selected" \
                || printf "Selection failed\n"
            ;;
        "e") 
            selection_prompt "Select a device to eject:" "$devices"
            selected=$(select_from "$devices") \
                && udisksctl unmount -b "/dev/$selected"?* \
                && udisksctl power-off -b "/dev/$selected" \
                || printf "Selection failed\n"
            ;;
        "p")
            selection_prompt "Select a device to power off:" "$devices"
            selected=$(select_from "$devices") \
                && udisksctl power-off -b "/dev/$selected" \
                || printf "Selection failed\n"
            ;;
        "q")
            exit 0 ;;
        *) 
            printf "Unknown option\n" ;;
    esac
    printf "\n"
done
