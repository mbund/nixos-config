{
  description = "Main desktop NixOS Configuration";

  inputs.nixpkgs.url = "nixpkgs";
  inputs.erasure.url = "github:mbund/nix-erasure";

  outputs = { self, nixpkgs, erasure }:
  {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        erasure.nixosModule
        ({ pkgs, ... }:
        {

          imports = [
            ./hardware-configuration.nix
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
            '';
            gc = {
              automatic = true;
              dates = "weekly";
              options = "";
            };
          };

          boot.loader.grub.configurationLimit = 10;
          boot.kernelPackages = pkgs.linuxPackages_latest;

          environment.systemPackages = with pkgs; [
            git
            vim
          ];

          networking = {
            hostName = "mbund-desktop";
            useDHCP = false;
            networkmanager.enable = true;
          };

          time.timeZone = "America/New_York";

          users.groups = {
            # make a new group for the files in /etc/nixos so some users are allowed to edit it
            nixos-configurator = { };
          };

          users.users = {
            mbund = {
              isNormalUser = true;
              extraGroups = [ "wheel" "nixos-configurator" "networkmanager" "libvirtd" "kvm" "adbusers" ];
              uid = 1000;
              initialPassword = "mbund";
            };
          };

          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "steam" "steam-original" "steam-runtime"
            "nvidia-x11" "nvidia-settings"
          ];

          # if wayland is enabled but not supported well (looking at you, nvidia) then
          # it wall cause a systemd timeout
          services.xserver = {
            enable = true;
            videoDrivers = [ "nvidia" ];
            # displayManager.defaultSession = "plasmawayland";
            displayManager.sddm = {
              enable = true;
              autoNumlock = true;
              # settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
            };

            desktopManager.plasma5 = {
              enable = true;
              useQtScaling = true;
              runUsingSystemd = true;
            };

            xkbOptions = "caps:swapescape";
          };

          programs.adb.enable = true;

          programs.kdeconnect.enable = true;

          # services.gnome.gnome-keyring.enable = true;
          # security.pam.services.login.enableGnomeKeyring = true;
          # security.pam.services.sddm.enableGnomeKeyring = true;
          # programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
          # programs.seahorse.enable = true;

          hardware.bluetooth.enable = true;
          services.xserver.wacom.enable = true;

          services.printing = {
            enable = true;
            drivers = with pkgs; [
              gutenprint
              gutenprintBin
              hplip
            ];
          };

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

          virtualisation.docker.enable = true;

          environment.erasure."root" = {
            storage-path = "/persist";

            btrfs = {
              enable = true;
              device = "/dev/mapper/nixos-root";
              subvolume = "root";
              mountpoint = "/";
              rollback-snapshot = "root-blank";
            };

            paths = [
              "/etc/machine-id"
              "/etc/NetworkManager/system-connections/"
              "/etc/nixos/"
              "/var/lib/bluetooth/"
              "/var/lib/docker/"
              "/var/lib/libvirt/"
            ];

            ignore = [
              "^/tmp/.*$"
              "^/var/lib/nixos/.*$"
              "^/var/lib/NetworkManager/.*$"
              "^/etc/NetworkManager/.*$"
              "^/root/.cache/.*$"
              "^/var/lib/systemd/.*$"
              "^/var/cache/.*$"
              "^/var/lib/sddm/\\.cache/.*$"
              "^/etc/pam\\.d/.*$"
              "^/etc/tmpfiles\\.d/.*$"
            ];
          };

          systemd.extraConfig = ''
            # this isn't some super powerful server running a million things, a service will
            # either stop in milliseconds or fail so the default 90s is way too long
            DefaultTimeoutStopSec=10s
          '';

          security.sudo.extraConfig = ''
            # rollback results in sudo lectures after each reboot
            Defaults lecture = never
          '';

          system = {
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
      ];
    };
  };
}
