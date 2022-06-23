{ pkgs, config, lib, ... }:
{
  # partitioning and drives
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
      device = "/dev/disk/by-label/boot";
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

  # create swapfile
  swapDevices = [
    {
      # To initialize a new swapfile on btrfs, you must first create it like so
      # truncate -s /swap/swapfile
      # chattr +C /swap/swapfile
      # btrfs property set /swap/swapfile compression none
      device = "/swap/swapfile";
      size = 6 * 1024;
    }
  ];

  # encryption
  boot.initrd.luks.devices = {
    "nixos-root" = {
      device = "/dev/disk/by-id/ata-ST500LM012_HN-M500MBB_S2TDJB0C230612-part3";
    };
  };

  # kernel
  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "ums_realtek" "sd_mod" "sr_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # bootloader
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/disk/by-id/ata-ST500LM012_HN-M500MBB_S2TDJB0C230612";
    enableCryptodisk = true;
  };

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
