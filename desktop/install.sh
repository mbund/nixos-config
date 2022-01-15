#!/usr/bin/env bash

# Enfore running as root
if [ "$EUID" != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

sgdisk --zap-all /dev/sda

sgdisk -n 0:0:+32MiB -t 0:ef00 /dev/sda

sgdisk -n 0:0:+128MiB /dev/sda
mkfs.ext4 -L bootloader /dev/sda2

sgdisk -n 0:0:0 /dev/sda
# must be `pbkdf2` for grub, in the future `argon2id` will be better
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

# Create swapfile
mkdir -p /mnt/swap
mount -o subvol=swap,compress=none,noatime /dev/mapper/nixos-root /mnt/swap
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile

# Mount bootloader
mkdir -p /mnt/boot
mount /dev/disk/by-label/bootloader /mnt/boot

# Get nixos configuration
mkdir -p /mnt/etc/nixos
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hardware-configuration.nix
cd /mnt/etc/nixos
git clone https://github.com/mbund/nixos-config .
nix registry add system git+file:///etc/nixos

echo "Run the following commands to install after your tweaking"
echo "sudo nixos-install --flake /etc/nixos#desktop"
echo "Then after booted in run:"
echo "nix registry pin nixpkgs"
echo "nix registry add system git+file:///etc/nixos"