{
  description = "mbund's home profile";
  # Install with `nix profile install .`
  # Upgrade packages with `nix profile upgrade '.*'`

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, utils, nixpkgs, neovim-nightly-overlay }:
    utils.lib.eachSystem ["x86_64-linux"] (system:
      let
        pkgs = import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
            overlays = [
              neovim-nightly-overlay.overlay
            ];
          };
      in {
        defaultPackage =
          pkgs.buildEnv {
            name = "mbund-home-profile";
            paths = [
              pkgs.neofetch
              pkgs.tldr
              pkgs.neovim-nightly
              pkgs.zsh
              pkgs.file
            ];
          };
      }
    );
}