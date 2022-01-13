{
  description = "marshmellow-roaster NixOS Configuration";

  inputs.nixpkgs.url = "nixpkgs";
  inputs.erasure.url = "flake:system?dir=erasure";
  #inputs.erasure.url = "/home/mbund/nixos-config/erasure";

  outputs = { self, nixpkgs, erasure }:
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
            '';
            gc = {
              automatic = true;
              dates = "weekly";
              options = "";
            };
          };

          environment.systemPackages = with pkgs; [
	    gparted
            git vim cryptsetup virt-manager
          ];

          networking = {
            hostName = "marshmellow-roaster";
            useDHCP = false;
            networkmanager.enable = true;
          };

          time.timeZone = "America/New_York";

          users.users = {
            mbund = {
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
              uid = 1000;
              initialPassword = "mbund";
            };
          };

          services.xserver = {
            enable = true;
            videoDrivers = [ "intel" ];
            displayManager.defaultSession = "plasmawayland";
            displayManager.sddm = {
              enable = true;
              settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
            };
            desktopManager.plasma5.enable = true;
          };

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

          fonts = {
            # fontDir.enable = true;
            fonts = with pkgs; [
              # nerdfonts
            ];
          };

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
