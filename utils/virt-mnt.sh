#!/bin/sh

# This script is used to mount a shared directory on a virt-manager virtual machine

# exit if not using sudo
if ! [ "$(id -u)" = 0 ]; then
   printf "The script need to be run as root." >&2
   exit 1
fi

# checking who is the current user
current_user=$(whoami)

[ -d "/home/$current_user/shared" ] || sudo -u "$current_user" mkdir "/home/$current_user/shared" && printf "%s\n" "Created directory /home/$current_user/shared"

mount -t 9p -o trans=virtio /host_device "/home/$current_user/shared" && printf "%s\n" "Shared directory mounted successfully under /home/$current_user/shared" || printf "%s\n" "Something went wrong. Check your virt-manager filesystem passthrough settings. (expected target path: /host_device)"
