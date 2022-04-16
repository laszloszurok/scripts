#!/usr/bin/env bash

prompt=" options:"
dmenu_cmd="dmenu -lh 26 -l 20 -c -i $@"

options=( "mount" "eject" "unmount" "power off" )

list_unmounted() {
    prompt=" partitions:"
    while selected=$(printf "%s\n" "${unmounted[@]}" | $dmenu_cmd -p "$prompt"); do
        # loop until the user types a valid option
        if [[ ! "${unmounted[*]}" =~ "${selected}" ]]; then
            continue
        fi
        break
    done
    printf "%s\n" "$selected"
}

list_mounted() {
    prompt=" partitions:"
    while selected=$(printf "%s\n" "${mounted[@]}" | $dmenu_cmd -p "$prompt"); do
        # loop until the user types a valid option
        if [[ ! "${mounted[*]}" =~ "${selected}" ]]; then
            continue
        fi
        break
    done
    printf "%s\n" "$selected"
}

list_devices() {
    prompt=" devices:"
    while selected=$(printf "%s\n" "${devices[@]}" | $dmenu_cmd -p "$prompt"); do
        # loop until the user types a valid option
        if [[ ! "${devices[*]}" =~ "${selected}" ]]; then
            continue
        fi
        break
    done
    printf "%s\n" "$selected"
}

while chosen=$(printf "%s\n" "${options[@]}" | $dmenu_cmd -p "$prompt") || exit; do

    info=$(lsblk -o name,type,label,fstype,size,mountpoints --list -n)
    devices=$(printf "%s\n" "$info" | grep "disk")
    partitions=$(printf "%s\n" "$info" | grep "part")
    mounted=$(printf "%s\n" "$partitions" | awk -F ' ?' '$NF != ""')
    unmounted=$(printf "%s\n" "$partitions" | awk -F ' ?' '$NF == ""')

    if [[ $chosen == "mount" ]]; then
        part=$(list_unmounted)
        if [[ -n $part ]]; then
            part=($part)
            name="${part[0]}"
            fs="${part[3]}"
            if [[ $fs == "ntfs" ]]; then # mount ntfs drives with correct unix permissions
                udisksctl mount -b "/dev/$name" -o dmask=022,fmask=133
            else
                udisksctl mount -b "/dev/$name"
            fi && \
            dunstify "Blockmenu" "$name mounted successfully" || \
            dunstify "Blockmenu" "Could not mount $name"
            break
        fi
    elif [[ $chosen == "unmount" ]]; then
        part=$(list_mounted)
        if [[ -n $part ]]; then
            part=($part)
            name="${part[0]}"
            udisksctl unmount -b "/dev/$name" && \
            dunstify "Blockmenu" "$name unmounted successfully" || \
            dunstify "Blockmenu" "Could not unmount $name"
            break
        fi
    elif [[ $chosen == "eject" ]]; then
        disk=$(list_devices)
        if [[ -n $disk ]]; then
            disk=($disk)
            name="${disk[0]}"
            udisksctl unmount -b "/dev/$name"?* && \
            udisksctl power-off -b "/dev/$name" && \
            dunstify "Blockmenu" "$name ejected successfully" || \
            dunstify "Blockmenu" "Could not eject $name"
            break
        fi
    elif [[ $chosen == "power off" ]]; then
        disk=$(list_devices)
        if [[ -n $disk ]]; then
            disk=($disk)
            name="${disk[0]}"
            udisksctl power-off -b "/dev/$name" && \
            dunstify "Blockmenu" "$name powerd off successfully" || \
            dunstify "Blockmenu" "Could not power off $name"
            break
        fi
    fi

done
