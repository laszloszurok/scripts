#!/bin/bash

# timezone and local
ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime

# hardware clock
hwclock --systohc

# generate locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# set language
echo LANG=en_US.UTF-8 >> /etc/locale.conf

# network
read -p "Chose a hostname: " hostname
echo $hostname >> /etc/hostname
echo "127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain    $hostname"

# installing some packages
pacman -S grub efibootmgr networkmanager wireless_tools wpa_supplicant os-prober mtools dosfstools base-devel linux-headers

# grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# account settings
passwd
read -p "Chose a username: " username
useradd -m $username
passwd $username
usermod -aG wheel,audio,video,optical,storage $username
EDITOR=nvim visudo
echo "Done. Type exit, then umount -a, then reboot and run bootstrap.sh"

