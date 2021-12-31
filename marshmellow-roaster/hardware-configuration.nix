{ pkgs, config, lib, ... }:
{
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
      fsType = "vfat";
    };

    "/swap" = {
      device = "/dev/mapper/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=swap" ];
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
      device = "/swap/swapfile";
      size = 6 * 1024;
    }
  ];

  boot.initrd = {
    luks.devices = {
      "nixos-root" = {
        # device = "/dev/disk/by-uuid/3c5e9e8f-c059-4c5a-8629-31f6da186348";
        device = "/dev/disk/by-label/encrypted-nixos-root";
      };
    };
  
    # Taken from:
    # https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
    postDeviceCommands = pkgs.lib.mkBefore ''
      mkdir -p /mnt

      # We first mount the btrfs root to /mnt
      # so we can manipulate btrfs subvolumes.
      mount -o subvol=/ /dev/mapper/enc /mnt

      # While we're tempted to just delete /root and create
      # a new snapshot from /root-blank, /root is already
      # populated at this point with a number of subvolumes,
      # which makes `btrfs subvolume delete` fail.
      # So, we remove them first.
      #
      # /root contains subvolumes:
      # - /root/var/lib/portables
      # - /root/var/lib/machines
      #
      # I suspect these are related to systemd-nspawn, but
      # since I don't use it I'm not 100% sure.
      # Anyhow, deleting these subvolumes hasn't resulted
      # in any issues so far, except for fairly
      # benign-looking errors from systemd-tmpfiles.
      btrfs subvolume list -o /mnt/root |
      cut -f9 -d' ' |
      while read subvolume; do
        echo "deleting /$subvolume subvolume..."
        btrfs subvolume delete "/mnt/$subvolume"
      done &&
      echo "deleting /root subvolume..." &&
      btrfs subvolume delete /mnt/root

      echo "restoring blank /root subvolume..."
      btrfs subvolume snapshot /mnt/root-blank /mnt/root

      # Once we're done rolling back to a blank snapshot,
      # we can unmount /mnt and continue on the boot process.
      umount /mnt
    '';

    availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "ums_realtek" "sd_mod" "sr_mod" ];
  };

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/disk/by-id/ata-ST500LM012_HN-M500MBB_S2TDJB0C230612";
    enableCryptodisk = true;
  };

  boot = {
    kernelModules = [ "kvm-intel" ];
  };
  
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
