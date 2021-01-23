#!/usr/bin/env bash

# internet connection and time
dhcpcd
ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo "internet connection ok" || `echo "no internet connection"; exit 1`
timedatectl set-ntp true

# partitioning
lsblk

disk=()
while IFS= read -r -d $'\0' device; do
    device=${device/\/dev\//}
    disk+=($device)
done < <(find "/dev/" -regex '/dev/sd[a-z]\|/dev/vd[a-z]\|/dev/hd[a-z]' -print0)

echo "
Available devices:"

for i in `seq 0 $((${#disk[@]}-1))`; do
    echo -e "${disk[$i]}"
done

read -p "Name of the device to partition (eg. sda): " device

while [[ ! $disk =~ (^|[[:space:]])$device($|[[:space:]]) ]]; do
    echo "Bad device name, please try again!"
    read -p "Name of the device to partition (eg. sda): " device
done

cfdisk /dev/"$device"

# mounting
partitions=$(lsblk -lfm | grep "$device" | awk '{if (NR!=1) print($1 " " $2)}')

echo "
List of partitions:"
echo "${partitions[@]}"

partition_list=$(echo "${partitions[@]}" | awk '{print($1)}')

echo "
Mounting partitions..."

while [[ "${#partition_list[@]}" -gt "0" ]]; do

    read -p "Number of the partition to mount (eg. 1): " partition_num

    while [[ ! $partition_list =~ (^|[[:space:]])$device$partition_num($|[[:space:]]) ]]; do
        echo "Bad partition number, please try again!"
        read -p "Number of the partition to mount (eg. 1): " partition_num
    done
    echo "Mounting $device$partition_num"

    fstype=$(echo "${partitions[@]}" | grep "$device$partition_num" | awk '{print($2)}')

    current="$device$partition_num"

    [ "$fstype" == "swap" ] && echo "This is a swap partition. Executing swapon..." && \
        swapon "$device$partition_num" && echo "Done!" || \
        read -p "Type the exact path to the mountpoint (eg. /mnt/boot): " mountpoint && \
        read -p "Mount $device$partition_num to $mountpoint? (y/n): " answer && \
        while [ "$answer" != "y" ] && [ "$answer" != "n" ]; do
            echo "Unknown option, try again!"
            read -p "Mount $device$partition_num to $mountpoint? (y/n): " answer
        done

    if [ "$answer" == "y" ]; then
        mkdir -p "$mountpoint"
        mount "$device$partition_num" "$mountpoint" && echo "Partition mounted successfully!" || echo "Something went wrong!"
    elif [ "$answer" == "n" ]; then
        echo "Partitioning not finished! Exiting..."
        exit 1
    fi

    # This deletes the current item from the list BUT actually removes matching prefixes for every item too,
    # for eg. if current=sda1, sda1 will be removed, sda11 will become 1. This is a problem!
    partition_list=( "${partition_list[@]/$current}" )
done

# base install
pacstrap /mnt base linux linux-firmware neovim

# filesystem table
genfstab -U /mnt >> /mnt/etc/fstab

echo "Done. Type the following command: arch-chroot /mnt"
