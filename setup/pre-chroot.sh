#!/bin/bash

# internet connection and time
dhcpcd
ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo "internet connection ok" || `echo "no internet connection"; exit 1`
timedatectl set-ntp true

# partitioning
lsblk
read -p "Path of device to partition (eg. /dev/sda): " device
fdisk $device

# creating filesystems
mkfs.fat -F32 "$device"1
mkswap "$device"2
mkfs.ext4 "$device"3

# mounting
mount "$device"3 /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount "$device"1 /mnt/boot/efi
swapon "$device"2

# base install
pacstrap /mnt base linux linux-firmware neovim

# filesystem table
genfstab -U /mnt >> /mnt/etc/fstab

echo "Done. Type the following command: arch-chroot /mnt"
