{
  description = "Live ISO confiugration";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.url = "nixpkgs";
    };

    home = {
      url = "github:mbund/nix-home?dir=mbund";
      inputs = {
        common.url = "github:mbund/nix-home?dir=common";
        cli.url = "github:mbund/nix-home?dir=cli";
        plasma.url = "github:mbund/nix-home?dir=plasma";
        firefox.url = "github:mbund/nix-home?dir=firefox";
      };
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, home }:
  {
    # nix build .#nixosConfigurations.live-iso.config.system.build.isoImage
    nixosConfigurations.live-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
        ({ pkgs, lib, config, modulesPath, ... }: {

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

              # allow rebuild while offline
              # https://nixos.org/manual/nix/stable/package-management/garbage-collection.html
              keep-outputs = true
              keep-derivations = true

              flake-registry = /etc/nixos/global-flake-registry.json
              accept-flake-config = true
              warn-dirty = false
              allow-import-from-derivation = true
            '';
            gc = {
              automatic = true;
              dates = "weekly";
              options = "";
            };
          };

          environment.systemPackages = with pkgs; [
            git cowsay
          ];

          networking = {
            hostName = "nixos-iso";
            useDHCP = false;
            networkmanager.enable = true;
          };

          time.timeZone = "America/New_York";

          users.users = {
            mbund = {
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" ];
              uid = 1000;
              initialPassword = "mbund";
            };
          };

          nixpkgs.config.allowUnfree = true;

          # if wayland is enabled but not supported well (looking at you, nvidia) then
          # it wall cause a systemd timeout
          services.xserver = {
            enable = true;
            # videoDrivers = [ "intel" "amd" "nvidia" ];
            displayManager.defaultSession = "plasmawayland";
            displayManager.sddm = {
              enable = true;
              autoNumlock = true;
              settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
            };

            desktopManager.plasma5 = {
              enable = true;
              # useQtScaling = true;
              # runUsingSystemd = true;
            };

            xkbOptions = "caps:swapescape";
          };

          programs.adb.enable = true;

          programs.kdeconnect.enable = true;

          services.gnome.gnome-keyring.enable = true;
          security.pam.services.login.enableGnomeKeyring = true;
          security.pam.services.sddm.enableGnomeKeyring = true;

          hardware.bluetooth.enable = true;
          services.xserver.wacom.enable = true;

          # 32bit opengl required for lutris epic games store
          hardware.opengl.driSupport32Bit = true;
          programs.steam.enable = true;

          programs.dconf.enable = true;

          services.pipewire = {
            enable = true;
            alsa = {
              enable = true;
              support32Bit = true; # this is probably not necessary
            };
            pulse.enable = true;
          };

          virtualisation.libvirtd = {
            enable = true;
            qemu.ovmf.enable = true;
            qemu.runAsRoot = false;
          };

          # Docker
          virtualisation.docker.enable = true;

          isoImage.isoName = "mbund-nixos-live.iso";

          # EFI + USB bootable
          isoImage.makeEfiBootable = true;
          isoImage.makeUsbBootable = true;

          isoImage.appendToMenuLabel = " live";

          boot.loader.grub.memtest86.enable = true;

          # An installation media cannot tolerate a host config defined file
          # system layout on a fresh machine, before it has been formatted.
          swapDevices = lib.mkImageMediaOverride [ ];
          fileSystems = lib.mkImageMediaOverride config.lib.isoFileSystems;

          system = {
            # Auto updating nix config. More useful for embedded systems
            # that we want to change remotely...
            autoUpgrade = {
              enable = false;
              allowReboot = true;
              flake = "github:mbund/nixos-config";
              flags = [
                "--recreate-lock-file"
                "--no-write-lock-file"
                "-L" # print build logs
              ];
              dates = "daily";
            };

            # Copy over full nixos-config to `/var/run/current-system/full-config/`
            # (available to the currently active derivation for safety/debugging)
            extraSystemBuilderCmds = "cp -rf ${./.} $out/full-config";

            # This value determines the NixOS release from which the default
            # settings for stateful data, like file locations and database versions
            # on your system were taken. It‘s perfectly fine and recommended to leave
            # this value at the release version of the first install of this system.
            # Before changing this value read the documentation for this option
            # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
            stateVersion = "21.11"; # Did you read the comment?
          };

        })

        home-manager.nixosModule home.homeNixOSModules."mbund@live-iso"
      ];
    };

  };
}
