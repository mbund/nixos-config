{
  description = "mbund's home-manager profile";
  # install with `nix run home-manager --no-write-lock-file -- switch --flake "./users/mbund#mbund"`
  # update with `home-manager switch --flake "./users/mbund#mbund"`

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cli.url = "./cli";
  };

  outputs = { self, ... }@inputs: {
    homeConfigurations = {
      mbund = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/mbund";
        username = "mbund";
        configuration = { config, lib, pkgs, ... }:
        {
          home.packages = with pkgs; [
            git
            neovim
            neofetch
          ];

          programs.home-manager.enable = true;
        } // inputs.cli.home;
      };
    };
  };
}
