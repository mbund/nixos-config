sgdisk --zap-all /dev/sda

sgdisk -n 0:0:+2MiB -t 0:ef02 /dev/sda

sgdisk -n 0:0:+1022MiB /dev/sda
mkfs.vfat -F 32 /dev/sda2
fatlabel /dev/sda2 bootloader

sgdisk -n 0:0:0 /dev/sda
# must be `pbkdf2` for grub, in the future `argon2id` will be better
cryptsetup luksFormat /dev/sda3 --pbkdf pbkdf2
cryptsetup luksOpen /dev/disk/by-label/encrypted-nixos-root nixos-root
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

mount -o subvol=root,compress=zstd,noatime /dev/mapper/nixos-root /mnt

nixos-generate-config --root /mnt --show-hardware-config
cd /mnt/etc/nixos
git clone https://github.com/mbund/nixos-config .