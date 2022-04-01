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
      size = 4 * 1024;
    }
  ];

  # Encryption
  boot.initrd.luks.devices = {
    "nixos-root" = {
      device = "/dev/disk/by-uuid/15f2e35e-feef-4cd0-ba7e-e47f4b3c9e6d";
    };
  };

  # Kernel
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc" "rtl8821ae" "r8169" ];
  boot.kernelModules = [ "kvm-intel" ];

  # Bootloader
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/disk/by-id/ata-ST1000LM024_HN-M101MBB_S32XJ9EH611653";
    enableCryptodisk = true;
  };

  # Network remote decrpyt
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;

    # Connect to server with our generated key, then provide the decryption password
    # ssh -i ~/.ssh/unlock_luks_zephyr -t -p 2222 root@my_server_address "read -s PASSWORD; echo \$PASSWORD > /crypt-ramfs/passphrase"

    authorizedKeys = [
      # Generate keys on each client that we want to be able to connect and provide the unlock password
      # ssh-keygen -t ed25519 -N "" -f ~/.ssh/unlock_luks_zephyr
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEoEanx0weICazylOHAB688WvXHXp3J61ZJAtGLYjcfP mbund@mbund-desktop"
    ];

    hostKeys = [
      # sudo ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/unlock_luks_host_ed25519_key
      "/etc/secrets/initrd/unlock_luks_host_ed25519_key"
    ];
  };

  powerManagement.cpuFreqGovernor = "ondemand";
  services.logind.lidSwitch = "ignore";

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}

