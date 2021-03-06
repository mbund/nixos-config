{ config, inputs, ... }: {
  imports = with inputs.self.nixosRoles; with inputs.self.nixosProfiles; [
    ./hardware-configuration.nix
    desktop

    nvidia
    gaming
  ];

  # networking options
  networking = {
    hostName = "kodai";
    useDHCP = false;
    interfaces.enp3s0f1.useDHCP = true;
    interfaces.wlp2s0.useDHCP = true;
    networkmanager.enable = true;
  };

  # power
  powerManagement.cpuFreqGovernor = "ondemand";
  services.auto-cpufreq.enable = true;
  services.tlp.enable = true;
  services.upower.enable = true;

  # erasure and persist
  environment.persist.root = {
    storage-path = "/persist";

    btrfs = {
      enable = true;
      device = "/dev/mapper/nixos-root";
      subvolume = "root";
      rollback-snapshot = "root-blank";
    };
    
    directories = [
      "/etc/NetworkManager/system-connections"
    ];
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
