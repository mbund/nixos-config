{
  description = "Installer ISO with latest kernel and nix features";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.url = "nixpkgs";
    };

    home = {
      url = "github:mbund/nix-home?dir=nixos-installer";
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
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };

    currentTime = nixpkgs.lib.removeSuffix "\n" (builtins.readFile (pkgs.runCommand "current-time" { }
      "date +'%F-%H-%M' > $out"
    ));
  in
  {
    # nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
    nixosConfigurations.installer-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ({ ... }: {
          isoImage.isoName = "nixos-installer-${currentTime}.iso";
        })

        ./nixos-installer.nix
      ];
    };

    # nix build .#nixosConfigurations.installer-iso-riced.config.system.build.isoImage
    nixosConfigurations.installer-iso-riced = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ({ ... }: {
          isoImage.isoName = "nixos-installer-riced-${currentTime}.iso";

          services.xserver.xkbOptions = "caps:swapescape";
        })

        ./nixos-installer.nix

        home-manager.nixosModule home.homeNixOSModules."nixos@nixos-installer"

      ];
    };

  };
}

