{ pkgs, config, lib, ... }:
{
  # Partitioning and drives
  fileSystems = {
    "/" = {
      device = "/dev/mapper/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };

    "/nix" = {
      device = "/dev/mapper/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };

    "/var/log" = {
      device = "/dev/mapper/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=log" "compress=zstd" "noatime" ];
    };

    "/persist" = {
      device = "/dev/mapper/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=persist" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-label/bootloader";
      fsType = "ext4";
    };

    "/swap" = {
      device = "/dev/mapper/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=swap" "compress=none" "noatime" ];
    };

    "/home" = {
      device = "/dev/mapper/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" ];
    };
  };

  # Create swapfile
  swapDevices = [
    {
      # To initialize a new swapfile on btrfs, you must first create it like so
      # truncate -s /swap/swapfile
      # chattr +C /swap/swapfile
      # btrfs property set /swap/swapfile compression none
      device = "/swap/swapfile";
      size = 20 * 1024;
    }
  ];

  # Encryption
  boot.initrd.luks.devices = {
    "nixos-root" = {
      # sdaX not dm-0
      device = "/dev/disk/by-uuid/";
    };
  };

  # Kernel
  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "ums_realtek" "sd_mod" "sr_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bootloader
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      version = 2;
      device = "nodev";
      efiSupport = true;
      enableCryptodisk = true;
    };
  };

  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
