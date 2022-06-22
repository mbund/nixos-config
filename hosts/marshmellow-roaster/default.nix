{ config, ... }: let
  
  home = {
    home.stateVersion = "22.05";
  };

in {
  imports = [
    ./hardware-configuration.nix
    ../../profiles/intel.nix
    
    ../../roles/desktop.nix
  ];

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
    storage-path = "/persist/home";
    
    btrfs = {
      enable = true;
      device = "/dev/mapper/nixos-root";
      subvolume = "home";
      rollback-snapshot = "home-blank";
    };
  };
}
