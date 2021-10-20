#!/bin/sh

# This script uses gio (gnome input/output), provided by gvfs (gnome virtual filesystem)
# to mount/unmount devices using mtp, from the command line.

print_usage() {
    printf "%s\n" "
Usage:
    gvfs_mtp <option>

Options:
    list       List available mtp devices
    mount      Mount all available mtp devices under /run/user/$(id -u)/gvfs/
    unmount    Unmount all mtp devices
"
}

if [ "$1" = "list" ]; then
    gio mount -li | grep -e ^Volume -e activation_root
elif [ "$1" = "mount" ]; then
    gio mount -li | awk -F= '{if(index($2,"mtp") == 1)system("gio mount "$2)}'
elif [ "$1" = "unmount" ]; then
    gio mount -u /run/user/$(id -u)/gvfs/*
else
    print_usage
fi
