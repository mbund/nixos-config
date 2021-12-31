{
  description = "marshmellow-roaster NixOS Configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.impermanence.url = "github:nix-community/impermanence";

  outputs = { self, nixpkgs, impermanence }:
  {
    nixosConfigurations.marshmellow-roaster = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
        impermanence.nixosModules.impermanence
        ({ ... }: {

          imports = [
            ./hardware-configuration.nix
          ];

          nix = {
            extraOptions = ''
              # enable the new standalone nix commands
              experimental-features = nix-command flakes

              # allow rebuild while offline
              # https://nixos.org/manual/nix/stable/package-management/garbage-collection.html
              # keep-outputs = true
              # keep-derivations = true
            '';
          };

          networking.hostName = "marshmellow-roaster";
          networking.networkmanager.enable = true;
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

          environment.persistence."/persist" = {
            directories = [
              "/etc/nixos"
              "/etc/NetworkManager/system-connections"
              "/var/lib/docker"
            ];
            files = [
              "/etc/machine-id" # journalctl fails to find logs from past boots
            ];
          };
          
          security.sudo.extraConfig = ''
            # rollback results in sudo lectures after each reboot
            Defaults lecture = never
          '';

        })
      ];
    };
  };
}
