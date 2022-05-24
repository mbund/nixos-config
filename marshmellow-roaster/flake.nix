{
  description = "marshmellow-roaster NixOS Configuration";

  inputs = {
    erasure.url = "github:mbund/nix-erasure";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, erasure, ... }@inputs:
    {
      nixosConfigurations.marshmellow-roaster = nixpkgs.lib.nixosSystem {
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
                  allow-import-from-derivation = true
                '';
                gc = {
                  automatic = true;
                  dates = "weekly";
                  options = "";
                };
              };

              environment.systemPackages = with pkgs; [
                git
                vim
                cryptsetup
              ];

              networking = {
                hostName = "marshmellow-roaster";
                useDHCP = false;
                networkmanager.enable = true;
              };

              time.timeZone = "America/New_York";

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

              services.xserver = {
                enable = true;
                videoDrivers = [ "intel" ];
                displayManager.startx.enable = true;
              };
              hardware.opengl.enable = true;
              programs.dconf.enable = true;
              programs.adb.enable = true;

              services.printing = {
                enable = true;
                drivers = with pkgs; [
                  gutenprint
                  gutenprintBin
                  hplip
                ];
              };
              services.avahi = {
                enable = true;
                nssmdns = true;
              };

              services.pipewire = {
                enable = true;
                alsa = {
                  enable = true;
                  support32Bit = true; # this is probably not necessary
                };
                pulse.enable = true;
              };

              # Docker
              virtualisation.docker.enable = true;

              # Virtualization
              boot.extraModprobeConfig = "options kvm_intel nested=1";
              virtualisation.libvirtd = {
                enable = true;
                qemu.ovmf.enable = true;
                qemu.runAsRoot = false;
              };

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
                  "/var/lib/docker/"
                ];

                ignore = [
                  "^/tmp/.*$"
                  "^/root/.cache/nix/.*$"
                  "^/root/.cache/mesa_shader_cache/.*$"
                  "^/var/lib/systemd/.*$"
                ];
              };

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
