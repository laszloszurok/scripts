#!/usr/bin/env bash

# internet connection and time
dhcpcd
ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo "internet connection ok" || `echo "no internet connection"; exit 1`
timedatectl set-ntp true &>/dev/null

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
partitions=$(lsblk -lfm | grep "^\($device\)[0-9]\+")

partition_list=$(echo "${partitions[@]}" | awk '{print($1)}')

echo "
Creating filesystems..."

while [[ ! -z "$partition_list" ]]; do
    echo "
    List of partitions:"
    echo "${partitions[@]}"

    read -p "Number of the partition to format (eg. 1): " partition_num

    while [[ ! $partition_list =~ (^|[[:space:]])$device$partition_num($|[[:space:]]) ]]; do
        echo "Bad partition number, please try again!"
        read -p "Number of the partition to format (eg. 1): " partition_num
    done
    echo "Formatting $device$partition_num"

    current="$device$partition_num"

    fs_options=("efi" "ext4" "swap")
    echo "Filesystem options: ${fs_options[@]}"
    read -p "Chose an option (eg. efi): " option
    while [[ ! "${fs_options[@]}" =~ (^|[[:space:]])$option($|[[:space:]]) ]]; do
        echo "Unknown option, please try again!"
        read -p "Chose an option (eg. efi): " option
    done

    case "$option" in
        "efi") mkfs.fat -F32 /dev/$device$partition_num && \
            echo "Mounting efi partition..." && \
            mkdir -p /mnt/boot/efi && \
            mount /dev/$device$partition_num /mnt/boot/efi && \
            echo "Done!" ;;
        "ext4") mkfs.ext4 /dev/$device$partition_num && \
            echo "Mounting root partition..." && \
            mount /dev/$device$partition_num /mnt && \
            echo "Done!" ;;
        "swap") mkswap /dev/$device$partition_num && \
            echo "Mounting swap partition..." && \
            swapon /dev/$device$partition_num && \
            echo "Done!" ;;
    esac

    # This deletes the current item from the list BUT actually removes matching prefixes for every item too,
    # for eg. if current=sda1, sda1 will be removed, sda11 will become 1. This is a problem!
    partition_list=( "${partition_list[@]/$current}" )
    partition_list=("${partition_list[@]}")
done

# base install
pacstrap /mnt base linux linux-firmware neovim

# filesystem table
genfstab -U /mnt >> /mnt/etc/fstab

echo "
Done. Type the following command: arch-chroot /mnt"
