{ pkgs, lib, config, modulesPath, ... }: {

  imports = [
    # base profiles
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/all-hardware.nix"

    # Let's get it booted in here
    "${modulesPath}/installer/cd-dvd/iso-image.nix"

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  nix = {
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" ];
      allowed-users = [ "*" ];
      binary-caches = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      binary-cache-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    package = pkgs.nixUnstable;
    extraOptions = ''
      # enable the new standalone nix commands
      experimental-features = nix-command flakes

      accept-flake-config = true
      warn-dirty = false
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "";
    };
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  networking = {
    hostName = "nixos-installer";
    useDHCP = false;
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

  users.users = {
    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      initialHashedPassword = "";
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "nixos" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" "SETENV" ];
        }
      ];
    }
  ];

  services.xserver = {
    enable = true;

    displayManager.defaultSession = "plasmawayland";

    displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

    displayManager.sddm = {
      enable = true;
      autoNumlock = true;
      settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
    };

    desktopManager.plasma5 = {
      enable = true;
      useQtScaling = true;
      runUsingSystemd = true;
    };
  };

  documentation.enable = false;
  documentation.nixos.enable = false;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  hardware.bluetooth.enable = true;

  programs.dconf.enable = true;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true; # this is probably not necessary
    };
    pulse.enable = true;
  };

  # EFI + USB bootable
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  isoImage.appendToMenuLabel = " installer";

  boot.loader.grub.memtest86.enable = true;

  # An installation media cannot tolerate a host config defined file
  # system layout on a fresh machine, before it has been formatted.
  swapDevices = lib.mkImageMediaOverride [ ];
  fileSystems = lib.mkImageMediaOverride config.lib.isoFileSystems;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
