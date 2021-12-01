{ pkgs, config, lib, ... }: {

  environment.pathsToLink = [ "/share/zsh" ];
  environment.sessionVariables.SHELL = "zsh";

  # A history file is screwed up otherwise :(
  # persist.state.directories = [ "/home/mbund/.local/share/zsh" ];

  home-manager.users.mbund.programs.zsh = {
    enable = true;
    # enableAutosuggestions = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "dirhistory" ];
    };

    dotDir = ".config/zsh";

    history = rec {
      size = 1000000;
      save = size;
      path = "$HOME/.local/share/zsh/history";
    };

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "b2609ca787803f523a18bb9f53277d0121e30389";
          sha256 = "01w59zzdj12p4ag9yla9ycxx58pg3rah2hnnf3sw4yk95w3hlzi6";
        };
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.4.0";
          sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
        };
      }
      {
        name = "you-should-use";
        src = pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-you-should-use";
          rev = "2be37f376c13187c445ae9534550a8a5810d4361";
          sha256 = "0yhwn6av4q6hz9s34h4m3vdk64ly6s28xfd8ijgdbzic8qawj5p1";
        };
      }
    ];
    
    shellAliases = {
      "c" = "clear";
    };

    initExtra = ''
      PROMPT="%F{blue}%m %~%b "$'\n'"%(?.%F{green}%Bλ%b.%F{red}?) %f"
    '';
  };
}