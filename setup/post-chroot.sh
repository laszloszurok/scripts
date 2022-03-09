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
read -rp "Chose a hostname: " hostname
echo "$hostname" >> /etc/hostname
echo "127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain    $hostname"

# installing some packages
pacman -S grub efibootmgr iwd os-prober mtools dosfstools base-devel linux-headers

# grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# netowrking setup
systemctl enable systemd-networkd systemd-resolved iwd
echo "[Match]
Name=en*

[Network]
DHCP=yes

[DHCPv4]
RouteMetric=10" > /etc/systemd/network/20-wired.network

echo "[Match]
Name=wl*

[Network]
DHCP=yes
IgnoreCarrierLoss=3s

[DHCPv4]
RouteMetric=20" > /etc/systemd/network/25-wireless.network

# account settings
passwd
read -rp "Chose a username: " username
useradd -m "$username"
passwd "$username"
usermod -aG wheel,audio,video,optical,storage "$username"
echo 'Defaults editor="/usr/bin/nvim -Z -u NORC"
%wheel ALL=(ALL) ALL
%wheel ALL=(ALL) NOPASSWD: /usr/bin/make clean install,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/pacman -Syyuw --noconfirm' > /etc/sudoers.d/settings

echo "Done. Type exit, then umount -a, then reboot and run bootstrap.sh"

