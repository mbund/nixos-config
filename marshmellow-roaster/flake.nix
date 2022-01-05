{
  description = "marshmellow-roaster NixOS Configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  {
    nixosConfigurations.marshmellow-roaster = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
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
            git vim cryptsetup 
      
            (writeShellApplication {
              name = "btrfs-diff";
              runtimeInputs = [ btrfs-progs coreutils gnused ];
              text = ''
                if [ "$EUID" != 0 ]; then
                  sudo "$0" "$@"
                  exit $?
                fi

                sudo mkdir -p /mnt
                sudo mount -o subvol=/ /dev/mapper/nixos-root /mnt

                OLD_TRANSID=$(sudo btrfs subvolume find-new /mnt/root-blank 9999999)
                OLD_TRANSID=''${OLD_TRANSID#transid marker was }

                sudo btrfs subvolume find-new "/mnt/root" "$OLD_TRANSID" |
                sed '$d' |
                cut -f17- -d' ' |
                sort |
                uniq |
                grep -v -f /etc/nixos/marshmellow-roaster/ignore |
                while read -r path; do
                  path="/$path"
                  # if [ -L "$path" ]; then
                  #  : # The path is a symbolic link, so is probably handled by NixOS already
                  # elif [ -d "$path" ]; then
                  #  : # The path is a directory, ignore
                  # else
                  #  echo "$path"
                  # fi
                  
                  echo "$path"
                done

                umount /mnt
              '';
            })
          ];

          networking = {
            hostName = "marshmellow-roaster";
            networkmanager.enable = true;

            # The global `networking.useDHCP` is deprecated, so instead list all explicitly
            # `$ nmcli device status`
            useDHCP = false;
            interfaces.enp5s0.useDHCP = true;
            interfaces.wlp9s0b1.useDHCP = true;
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

          services.xserver = {
            enable = true;
            displayManager.sddm.enable = true;
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

          virtualisation.docker.enable = true;

          systemd.tmpfiles.rules = [
            "L /etc/nixos - - - - /persist/etc/nixos"
            "L /etc/NetworkManager/system-connections - - - - /persist/etc/NetworkManager/system-connections"
            "L /etc/machine-id - - - - /persist/etc/machine-id"
            "L /var/lib/docker - - - - /persist/var/lib/docker"
          ];

          # environment.persistence."/persist" = {
          #   directories = [
          #     "/etc/nixos"
          #     "/etc/NetworkManager/system-connections"
          #     "/var/lib/docker"
          #   ];
          #   files = [
          #     "/etc/machine-id" # journalctl fails to find logs from past boots
          #   ];
          # };
          
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
