{
  description = "zsh configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachSystem ["x86_64-linux"] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        writeToFileShell = str: path: ''
          mkdir -p ${builtins.dirOf path}
          printf ${nixpkgs.lib.escapeShellArg str} > ${path}
          chmod -w ${path}
        '';
      in {
        packages = [ pkgs.zsh pkgs.oh-my-zsh pkgs.zsh-z pkgs.starship ];
        overlay = {};
        postBuild =
          writeToFileShell ''
            source $HOME/.config/zsh/.zshenv
          ''
          "$HOME/.zshenv" ++
          writeToFileShell ''
            ZDOTDIR=$HOME/.config/zsh
            ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
            ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
          ''
          "$HOME/.config/zsh/.zshenv" ++
          writeToFileShell ''
            plugins=(git dirhistory)

            source $ZSH/oh-my-zsh.sh

          ''
          "$HOME/.config/zsh/.zshrc";
      }
    );
}