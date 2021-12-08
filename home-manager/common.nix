{ config, pkgs, ... }:

{
  # nixpkgs.config.allowUnfree = true;
  programs = {

    git = {
      enable = true;
      userName = "mbund";
    };

    zsh = {
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
        "ls" = "lsd";
      };

      # initExtra = ''
      #   PROMPT="%F{blue}%m %~%b "$'\n'"%(?.%F{green}%Bλ%b.%F{red}?) %f"
      # '';
    };

    starship = {
      enable = true;
      settings = {
        format = pkgs.lib.concatStrings [
          "$username" "$hostname" "$directory"
          "$git_branch" "$git_state" "$git_status"
          "$zig" "$cmd_duration"
          "$line_break"
          "$jobs" "$battery" "$nix_shell" "$character"
        ];
        cmd_duration = {
          min_time = 1;
        };
        directory = {
          truncation_length = 10;
        };
        git_status = {
          ahead = "⇡$count";
          diverged = "⇕⇡$ahead_count⇣$behind_count";
          behind = "⇣$count";
          modified = "*";
        };
        nix_shell = {
          format = "[$state ]($style)";
          impure_msg = "λ";
          pure_msg = "λλ";
        };
        package.disabled = true;
      };
    };

    # kitty = {
    #   enable = true;
    #   font = {
    #     name = "JetBrains Mono Medium Nerd Font Complete";
    #     package = pkgs.jetbrains-mono;
    #   };
    # };

    # kitty.enable = true;
    lsd.enable = true;
    # feh.enable = true;
    direnv.enable = true;
    home-manager.enable = true;
  };

  services = {
    lorri.enable = true;
    picom = {
      enable = true;
      shadow = false;
      fade = true;
      fadeDelta = 4;
      blur = true;
      inactiveOpacity = "0.90";

      # fixes flickering problems with glx backend
      backend = "xrender";
    };
    unclutter.enable = true;
  };

  dconf.enable = true; # for wpgtk

  # extra programs that don't have extra config
  home.packages = with pkgs; [
    vscodium
    zip unzip

    # (callPackage ../pkgs/pywal.nix {
    #   buildPythonPackage = python39Packages.buildPythonPackage;
    #   fetchPypi = python39Packages.fetchPypi;
    #   isPy3k = true;
    # })
    pywal
    kitty
    # wpgtk
    feh
    # xsettingsd
    # python2

    # gimp
    # inkscape
    # krita
    firefox
    vim
  ];

  home.file = {
    awesome = {
      # this is a bunch of symlinks which eventually point to this git repository.
      # use `readlink $(readlink $(readlink ~/.config/awesome))` to find final symlink.
      # TODO: un-hardcode this git repository location `$HOME/nix-config`
      # useful so that you can make changes directly in this git repository and have it
      # take effect without doing a nixos-rebuild
      source = config.lib.file.mkOutOfStoreSymlink (config.home.homeDirectory + "/nix-config/dotfiles/awesome");
      # source = ../awesome;
      target = "./.config/awesome";
    };

    kitty = {
      source = config.lib.file.mkOutOfStoreSymlink (config.home.homeDirectory + "/nix-config/dotfiles/kitty");
      target = "./.config/kitty";
    };

    xcompose = {
      source = config.lib.file.mkOutOfStoreSymlink (config.home.homeDirectory + "/nix-config/dotfiles/compose");
      # source = ./compose;
      target = ".XCompose";
    };
  };

  xsession = {
    windowManager.awesome.enable = true;
  };

  home.stateVersion = "21.11";

}
