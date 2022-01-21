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
      device = "/dev/disk/by-label/boot";
      fsType = "ext4";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-label/UEFI-ESP";
      fsType = "vfat";
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

  # enable fstrim because I am running on an ssd
  services.fstrim.enable = true;

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
      device = "/dev/disk/by-uuid/ad3f0a0f-93ac-40c6-a294-279c70347d4e";
    };
  };

  # Kernel
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bootloader
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
    grub = {
      device = "nodev";
      efiSupport = true;
      enableCryptodisk = true;
    };
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
