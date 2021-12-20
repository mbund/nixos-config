{
  description = "CLI configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
      flake = false;
    };
  };

  outputs = { self, ... }@inputs: {
    home = {
      home.packages = with pkgs; [
        neofetch
      ];

      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";

        enableCompletion = true;
        enableAutosuggestions = true;
        oh-my-zsh = {
          enable = true;
          plugins = [ "git" "vi-mode" ];
        };

        plugins = [
          {
            name = "zsh-syntax-highlighting";
            src = inputs.zsh-syntax-highlighting;
          }
        ];
      };

      home.file.".bashrc".text = ''
        # Set zsh has the default shell if it isn't already
        export SHELL=`which zsh`
        [ -z "$ZSH_VERSION" ] && exec "$SHELL" -l
      '';
    };
  };
}
