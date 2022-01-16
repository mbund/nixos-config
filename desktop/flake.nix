{
  description = "Main desktop NixOS Configuration";

  inputs.nixpkgs.url = "flake:nixpkgs";
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
            package = pkgs.nixUnstable;
            autoOptimiseStore = true;
            trustedUsers = [ "root" ];
            allowedUsers = [ "*" ];
            extraOptions = ''
              # enable the new standalone nix commands
              experimental-features = nix-command flakes

              # allow rebuild while offline
              # https://nixos.org/manual/nix/stable/package-management/garbage-collection.html
              keep-outputs = true
              keep-derivations = true

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
            git vim
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
              extraGroups = [ "wheel" "networkmanager" "libvirtd" "nixos-configurator" ];
              uid = 1000;
              initialPassword = "mbund";
            };
          };

          # required on the system level for
          # - nvidia drivers
          # - steam
          nixpkgs.config.allowUnfree = true;

          services.xserver = {
            enable = true;
            videoDrivers = [ "nvidia" ];
            # displayManager.defaultSession = "plasmawayland";
            displayManager.sddm = {
              enable = true;
              settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
            };
            desktopManager.plasma5.enable = true;
          };

          hardware.bluetooth.enable = true;
          services.xserver.wacom.enable = true;

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
          
          # Virtualization
          boot.extraModprobeConfig = "options kvm_intel nested=1";
          virtualisation.libvirtd.enable = true;

          # Docker
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
