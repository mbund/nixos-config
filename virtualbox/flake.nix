{
  description = "Virtualbox NixOS Configuration";

  inputs.nixpkgs.url = "flake:nixpkgs";

  outputs = { self, nixpkgs }:
  {
    nixosConfigurations.virtualbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          
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

          networking.hostName = "virtualbox";
          time.timeZone = "America/New_York";

          users.users = {
            mbund = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
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

          boot.loader.grub = {
            enable = true;
            version = 2;
            device = "/dev/sda";
          };

          system.stateVersion = "21.11";
        })
      ];
    };
  };
}
