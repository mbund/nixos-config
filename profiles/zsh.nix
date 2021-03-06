{ pkgs, config, lib, ... }:
let

  home = {
    home.packages = with pkgs; [
      nix-index
    ];

    programs.zsh = {
      enable = true;

      dotDir = "./config/zsh";

      enableAutosuggestions = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      autocd = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
      plugins = [
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
        "lg" = "lazygit";
        "git-sign-github" = "git config user.name mbund && git config user.email 25110595+mbund@users.noreply.github.com && git config user.signingkey 6C8949C0713C5B3C";
      };

      shellGlobalAliases = {
        "UUID" = "$(uuidgen | tr -d \\n)";
      };

      initExtra = ''
        # create custom command not found handler by searching through nix-index for it
      
        command_not_found_handle() {
          # taken from http://www.linuxjournal.com/content/bash-command-not-found
          # - do not run when inside Midnight Commander or within a Pipe
          if [ -n "''${MC_SID-}" ] || ! [ -t 1 ]; then
              >&2 echo "$1: command not found"
              return 127
          fi
          cmd=$1
          attrs=$(${pkgs.nix-index}/bin/nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$cmd")
          len=$(echo -n "$attrs" | grep -c "^")
          case $len in
            0)
              >&2 echo "$cmd: command not found in nixpkgs (run nix-index to update the index)"
              ;;
            *)
              >&2 echo "$cmd was found in the following derivations:\n"
              while read attr; do
                >&2 echo "nixpkgs#$attr"
              done <<< "$attrs"
              ;;
          esac
          return 127 # command not found should always exit with 127
        }

        command_not_found_handler() {
          command_not_found_handle $@
          return $?
        }
      

        # send notifications on ending long running commands

        cmdignore=(htop tmux top vim)

        # end and compare timer, notify-send if needed
        function notifyosd-precmd() {
          retval=$?
          if [ ! -z "$cmd" ]; then
            cmd_end=`date +%s`
            ((cmd_time=$cmd_end - $cmd_start))
          fi
          if [ $retval -eq 0 ]; then
            cmdstat="???"
          else
            cmdstat="???"
          fi
          if [ ! -z "$cmd" ] && [[ $cmd_time -gt 3 ]]; then
            ${pkgs.libnotify}/bin/notify-send -a command_complete -i utilities-terminal -u low "$cmdstat $cmd" "in `date -u -d @$cmd_time +'%T'`"
            echo -e '\a'
          fi
          unset cmd
        }

        # make sure this plays nicely with any existing precmd
        precmd_functions+=( notifyosd-precmd )

        # get command name and start the timer
        function notifyosd-preexec() {
            cmd=$1
          cmd_start=`date +%s`
        }
      
        # use powerlevel10k prompt
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      '';
    };

    # home.persistance."/persist/home/${config.home.user}".directories = [ ".local/share/zsh" ];
  };

in
{
  # environment.persist.home.directories = [ "/home/mbund/.local/share/zsh" ];

  home-manager.users.mbund = home;
}
