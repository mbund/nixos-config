{
  description = "Main desktop NixOS Configuration";

  inputs = {
    erasure.url = "github:mbund/nix-erasure";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, erasure, ... }@inputs: {
    genNixOSConfigurations = parentInputs: {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          erasure.nixosModule
          parentInputs.mbund-gnome.nixosModule
          ({ pkgs, config, ... }:
            {

              imports = [
                ./hardware-configuration.nix
              ];

              # Nix options
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
              nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
                "steam"
                "steam-original"
                "steam-runtime"
                "nvidia-x11"
                "nvidia-settings"
                "hplip"
              ];

              # Hardware options
              boot.loader.grub.configurationLimit = 10;
              boot.kernelPackages = pkgs.linuxPackages_latest;
              hardware.nvidia.modesetting.enable = true;
              hardware.opengl = {
                enable = true;
                extraPackages = with pkgs; [
                  nvidia-vaapi-driver
                ];
              };

              # Networking options
              networking = {
                hostName = "mbund-desktop";
                useDHCP = false;
                networkmanager.enable = true;

                extraHosts = ''
                  192.168.1.103 zephyr
                '';
              };
              services.openssh.enable = true;
              networking.firewall.allowedTCPPorts = [
                22 # ssh
                5900 # vnc
              ];

              # User options
              users.mutableUsers = false;
              users.groups = {
                # make a new group for the files in /etc/nixos so some users are allowed to edit it
                nixos-configurator = { };
                mbund = { };
              };
              programs.zsh.enable = true;
              users.users = {
                mbund = {
                  isNormalUser = true;
                  group = "mbund";
                  shell = pkgs.zsh;
                  extraGroups = [
                    "audio"
                    "video"
                    "render"

                    "users"
                    "wheel"

                    "nixos-configurator"
                    "networkmanager"
                    "libvirtd"
                    "kvm"
                    "docker"
                    "adbusers"
                  ];
                  uid = 1000;
                  passwordFile = "/persist/etc/mbund-passwd"; # mkpasswd -m sha-512 > /persist/etc/mbund-passwd
                };
              };

              # Desktop options
              services.mbund-gnome.enable = true;
              services.xserver = {
                enable = true;
                videoDrivers = [
                  "nvidia"
                ];

                exportConfiguration = true;
                deviceSection = ''
                  Option "AllowSHMPixmaps" "on"
                  Option "DRI3" "on"
                '';
              };
              programs.adb.enable = true;
              services.printing = {
                enable = true;
                drivers = with pkgs; [
                  gutenprint
                  gutenprintBin
                  foo2zjs
                  # hplipWithPlugin
                ];
              };
              services.avahi = {
                enable = true;
                nssmdns = true;
              };
              environment.systemPackages = with pkgs; [
                git
                vim
              ];

              # misc
              time.timeZone = "America/New_York";
              programs.steam.enable = true;
              virtualisation.docker.enable = true;
              virtualisation.libvirtd = {
                enable = true;
                qemu.ovmf.enable = true;
                qemu.runAsRoot = false;
              };

              # Opt-in state erasure
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

              # Misc
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
  };
}
