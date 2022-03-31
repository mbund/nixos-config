#!/usr/bin/env bash

# Enfore running as root
if [ "$EUID" != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

sgdisk --zap-all /dev/sda

sgdisk -n 0:0:+2MiB -t 0:ef02 /dev/sda

sgdisk -n 0:0:+1022MiB /dev/sda
mkfs.vfat -F 32 /dev/sda2
fatlabel /dev/sda2 bootloader

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

# Create all directories
mount -o subvol=root,compress=zstd,noatime /dev/mapper/nixos-root /mnt
# mkdir -p /mnt/{home,nix,persist,var/log,boot,swap}

# mount -o subvol=home,compress=zstd /dev/mapper/nixos-root /mnt/home
# mount -o subvol=nix,compress=zstd,noatime /dev/mapper/nixos-root /mnt/nix
# mount -o subvol=persist,compress=zstd,noatime /dev/mapper/nixos-root /mnt/persist
# mount -o subvol=log,compress=zstd,noatime /dev/mapper/nixos-root /mnt/var/log

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
echo "sudo nixos-install --flake /etc/nixos#marshmellow-roaster"
echo "Then after booted in run:"
echo "nix registry add system git+file:///etc/nixos"