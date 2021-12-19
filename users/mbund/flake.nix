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

    zsh.url = "./zsh";
  };

  outputs = { self, utils, nixpkgs, neovim-nightly-overlay }@inputs:
    utils.lib.eachSystem ["x86_64-linux"] (system:
      let
        custom = with inputs; [ zsh ];

        pkgs = import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
            overlays = [
              neovim-nightly-overlay.overlay
            ];
          };

        dotfiles = "~/nix-config/users/mbund/dotfiles";
      in {
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/buildenv/default.nix
        defaultPackage =
          pkgs.buildEnv {
            name = "mbund-home-profile";
            paths = [
	            pkgs.git
              pkgs.neofetch
              pkgs.tldr
              pkgs.neovim-nightly
              pkgs.zsh
              pkgs.file
              pkgs.firefox
            ];
            
            postBuild = ''
              # Link config directories
              echo "source ${dotfiles}/.config/zsh/.zshenv" > ~/.zshenv
              ln --symbolic --force ${dotfiles}/zsh/ ~/.config/zsh/.zshenv
            '';
          };
      }
    );
}
