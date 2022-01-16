#!/usr/bin/env bash

# Enfore running as root
if [ "$EUID" != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

sgdisk --zap-all /dev/nvme0n1

# /boot
sgdisk -n 0:0:+128MiB /dev/nvme0n1
mkfs.ext4 -L boot /dev/nvme0n1p1

# UEFI ESP
sgdisk -n 0:0:+64MiB -t 0:ef00 /dev/nvme0n1
mkfs.vfat -F 32 -n UEFI-ESP /dev/nvme0n1p2

# / (root)
sgdisk -n 0:0:0 /dev/nvme0n1
# must be `pbkdf2` for grub, in the future `argon2id` will be better
cryptsetup luksFormat /dev/nvme0n1p3 --pbkdf pbkdf2
cryptsetup luksOpen /dev/nvme0n1p3 nixos-root
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

# Mount UEFI ESP partition
mkdir -p /mnt/boot/efi
mount /dev/disk/by-label/UEFI-ESP /mnt/boot/efi

# Get nixos configuration
mkdir -p /mnt/etc/nixos
cd /mnt/etc/nixos
git clone https://github.com/mbund/nixos-config .
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hardware-configuration.nix
# nix registry add system git+file:///mnt/etc/nixos

echo "Run the following commands to install after your tweaking"
echo "sudo nixos-install --flake /mnt/etc/nixos#desktop --recreate-lock-file --no-root-password"
echo "Then after booted in run:"
echo "nix registry pin nixpkgs"
echo "nix registry add system git+file:///etc/nixos"