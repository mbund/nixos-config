{
  description = "Installer ISO with latest kernel and nix features";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.url = "nixpkgs";
    };

    home = {
      url = "path:/home/mbund/nix-home/nixos-installer";
      inputs = {
        common.url = "path:/home/mbund/nix-home/common";
        cli.url = "path:/home/mbund/nix-home/cli";
        plasma.url = "path:/home/mbund/nix-home/plasma";
        firefox.url = "path:/home/mbund/nix-home/firefox";
      };
      # url = "github:mbund/nix-home?dir=nixos";
      # inputs = {
      #   common.url = "github:mbund/nix-home?dir=common";
      #   cli.url = "github:mbund/nix-home?dir=cli";
      #   plasma.url = "github:mbund/nix-home?dir=plasma";
      #   firefox.url = "github:mbund/nix-home?dir=firefox";
      # };
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, home }:
  {
    # nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
    nixosConfigurations.installer-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
        ({ ... }: {
          isoImage.isoName = "nixos-installer.iso";
        })

        ./nixos-installer.nix
      ];
    };

    # nix build .#nixosConfigurations.installer-iso-riced.config.system.build.isoImage
    nixosConfigurations.installer-iso-riced = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
        ({ ... }: {
          isoImage.isoName = "nixos-installer-riced.iso";

          services.xserver.xkbOptions = "caps:swapescape";
        })

        ./nixos-installer.nix

        home-manager.nixosModule home.homeNixOSModules."nixos@nixos-installer"

      ];
    };

  };
}

