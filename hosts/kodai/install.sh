#!/usr/bin/env bash

set -e
set -x

# Enforce running as root
if [ "$EUID" != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

sgdisk --zap-all /dev/sda

# bios boot
sgdisk -n 0:0:+2MiB -t 0:ef02 /dev/sda

# /boot
sgdisk -n 0:0:+8GiB /dev/sda
mkfs.ext4 -L boot /dev/sda2

# encrypted / (root)
sgdisk -n 0:0:0 /dev/sda
# must be `pbkdf2` for grub, in the future `argon2id` will be better
echo "Asking for drive encryption password"
cryptsetup luksFormat /dev/sda3 --pbkdf pbkdf2
cryptsetup luksOpen /dev/sda3 nixos-root
mkfs.btrfs /dev/mapper/nixos-root

# create btrfs subvolumes
mkdir -p /mnt
mount /dev/mapper/nixos-root /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/log
btrfs subvolume create /mnt/persist
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/swap

# create blank snapshots
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
btrfs subvolume snapshot -r /mnt/home /mnt/home-blank
umount /mnt

# mount root /mnt
mount -o subvol=root,compress=zstd,noatime /dev/mapper/nixos-root /mnt

# create and mount subvolume directories
mkdir -p /mnt/{home,nix,persist,var/log}
mount -o subvol=home,compress=zstd /dev/mapper/nixos-root /mnt/home
mount -o subvol=nix,compress=zstd,noatime /dev/mapper/nixos-root /mnt/nix
mount -o subvol=persist,compress=zstd,noatime /dev/mapper/nixos-root /mnt/persist
mount -o subvol=log,compress=zstd,noatime /dev/mapper/nixos-root /mnt/var/log

# create swapfile
mkdir -p /mnt/swap
mount -o subvol=swap,compress=none,noatime /dev/mapper/nixos-root /mnt/swap
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile

# mount bootloader
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# get nixos configuration
mkdir -p /mnt/etc/nixos
git clone https://github.com/mbund/nixos-config /mnt/etc/nixos

# display nixos's autogenerated hardware config to help write the remainder
echo "---------[ nixos autogenerated hardware config ]---------"
nixos-generate-config --show-hardware-config
echo "---------------------------------------------------------"
