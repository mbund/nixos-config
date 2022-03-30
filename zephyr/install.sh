#!/usr/bin/env bash

set -e
set -x

# Enforce running as root
if [ "$EUID" != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

sgdisk --zap-all /dev/sda

# BIOS boot
sgdisk -n 0:0:+2MiB -t 0:ef02 /dev/sda

# /boot
sgdisk -n 0:0:+8GiB /dev/sda
mkfs.ext4 -L boot /dev/sda1

# / (root)
sgdisk -n 0:0:0 /dev/sda
# must be `pbkdf2` for grub, in the future `argon2id` will be better
echo "Asking for drive encryption password"
cryptsetup luksFormat /dev/sda3 --pbkdf pbkdf2
cryptsetup luksOpen /dev/sda3 nixos-root
mkfs.btrfs /dev/mapper/nixos-root

mkdir -p /mnt
mount /dev/mapper/nixos-root /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/log
btrfs subvolume create /mnt/persist
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/swap
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
umount /mnt

# Mount root /mnt
mount -o subvol=root,compress=zstd,noatime /dev/mapper/nixos-root /mnt

# Create and mount subvolumes
mkdir -p /mnt/{home,nix,persist,var/log}
mount -o subvol=home,compress=zstd /dev/mapper/nixos-root /mnt/home
mount -o subvol=nix,compress=zstd,noatime /dev/mapper/nixos-root /mnt/nix
mount -o subvol=persist,compress=zstd,noatime /dev/mapper/nixos-root /mnt/persist
mount -o subvol=log,compress=zstd,noatime /dev/mapper/nixos-root /mnt/var/log

# Create swapfile
mkdir -p /mnt/swap
mount -o subvol=swap,compress=none,noatime /dev/mapper/nixos-root /mnt/swap
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile

# Mount bootloader
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Set up user password
mkdir -p /mnt/persist/etc
echo "Asking for user password"
mkpasswd -m sha-512 > /mnt/persist/etc/mbund-passwd

# Get nixos configuration
mkdir -p /mnt/etc/nixos

# BY HAND
# git clone https://github.com/mbund/nixos-config .
# cd /mnt/etc/nixos

# sudo nixos-generate-config --root /mnt --show-hardware-config

# write your system flake.nix and hardware-configuration here
# sudo nixos-install --flake /mnt/etc/nixos#zephyr --recreate-lock-file --no-root-password

# on reboot, you'll need to redownload your flake.nix and hardware-configuration.nix back into /etc/nixos because the erasure module will delete it

# then when you make changes to your system do
# sudo nixos-rebuild switch --flake /mnt/etc/nixos#zephyr

