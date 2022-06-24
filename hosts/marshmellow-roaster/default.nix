{ config, ... }:
let

  home = {
    home.stateVersion = "21.11";
  };

in
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/intel.nix
    ../../profiles/location/JFK.nix

    ../../roles/desktop.nix
  ];

  # networking options
  networking = {
    hostName = "marshmellow-roaster";
    useDHCP = false;
    interfaces.enp5s0.useDHCP = true;
    interfaces.wlp9s01b.useDHCP = true;
    networkmanager.enable = true;
  };

  # basic home state
  home-manager.users.mbund = home;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  # erasure and persist
  environment.persist.root = {
    storage-path = "/persist";

    btrfs = {
      enable = true;
      device = "/dev/mapper/nixos-root";
      subvolume = "root";
      rollback-snapshot = "root-blank";
    };
  };

  environment.persist.home = {
    storage-path = "/persist";

    btrfs = {
      enable = true;
      device = "/dev/mapper/nixos-root";
      subvolume = "home";
      rollback-snapshot = "home-blank";
    };
  };

  # system.activationScripts = {
  #   homedirs.text = builtins.concatStringsSep "\n" (map
  #     (dir: ''
  #       mkdir -p ${dir}
  #       chown mbund:mbund ${dir}
  #     '')
  #     (builtins.filter (lib.hasPrefix "/home/mbund") config.environment.persistence.directories));
  #   homefiles.text = builtins.concatStringsSep "\n" (map
  #     (file: ''
  #       mkdir -p $(dirname ${file})
  #       touch ${file}
  #       chown mbund:mbund ${file}
  #     '')
  #     (builtins.filter (lib.hasPrefix "/home/mbund") config.environment.persistence.files));
  # };
}
