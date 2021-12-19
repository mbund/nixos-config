{
  description = "zsh configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... }:
    utils.lib.eachSystem ["x86_64-linux"] (system:
      let
        pkgs = import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
          };

        writeToFileShell = str: path: ''
          mkdir -p ${builtins.dirOf path}
          chmod +w ${path}
          printf ${nixpkgs.lib.escapeShellArg str} > ${path}
          chmod -w ${path}
        '';
      in {
        packages = [ pkgs.zsh pkgs.oh-my-zsh pkgs.starship pkgs.zsh-z
        
          (pkgs.runCommand "home-generation" { preferLocalBuild = true; } "cd /home/mbund && touch yellow")
        
        ];
        postBuild = "";
      }
    );
}