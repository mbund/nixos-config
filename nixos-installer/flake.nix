{
  description = "Installer ISO with latest kernel and nix features";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager }:
    {
      # nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
      nixosConfigurations.installer-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ({ pkgs, lib, config, modulesPath, ... }: {
            imports = [
              # base profiles
              "${modulesPath}/profiles/base.nix"
              "${modulesPath}/profiles/all-hardware.nix"

              # Let's get it booted in here
              "${modulesPath}/installer/cd-dvd/iso-image.nix"

              # Provide an initial copy of the NixOS channel so that the user
              # doesn't need to run "nix-channel --update" first.
              "${modulesPath}/installer/cd-dvd/channel.nix"
            ];

            # Build the iso with the kernel that works best for you
            boot.kernelPackages = pkgs.linuxPackages_latest;
            # boot.kernelPackages = pkgs.linuxKernel.packages.linux_4_19;

            # Needed for https://github.com/NixOS/nixpkgs/issues/58959
            boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

            nix = {
              settings = {
                auto-optimise-store = true;
                trusted-users = [ "root" ];
                allowed-users = [ "*" ];
                binary-caches = [
                  "https://cache.nixos.org"
                  "https://nix-community.cachix.org"
                ];
                binary-cache-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              };
              package = pkgs.nixUnstable;
              extraOptions = ''
                # enable the new standalone nix commands
                experimental-features = nix-command flakes

                accept-flake-config = true
                warn-dirty = false
              '';
              gc = {
                automatic = true;
                dates = "weekly";
                options = "";
              };
            };

            environment.systemPackages = with pkgs; [
              git
              gparted
              firefox
              wget
              curl
            ];

            networking = {
              hostName = "nixos-installer";
              useDHCP = false;
              networkmanager.enable = true;
            };

            time.timeZone = "America/New_York";

            users.users = {
              nixos = {
                isNormalUser = true;
                extraGroups = [ "wheel" "networkmanager" ];
                initialHashedPassword = "";
              };
            };

            security.sudo.extraRules = [
              {
                users = [ "nixos" ];
                commands = [
                  {
                    command = "ALL";
                    options = [ "NOPASSWD" "SETENV" ];
                  }
                ];
              }
            ];

            services.xserver = {
              enable = true;

              # displayManager.defaultSession = "plasmawayland";

              displayManager.autoLogin = {
                enable = true;
                user = "nixos";
              };

              displayManager.sddm = {
                enable = true;
                autoNumlock = true;
                settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
              };

              desktopManager.plasma5 = {
                enable = true;
                useQtScaling = true;
                runUsingSystemd = true;
              };
            };

            documentation.enable = false;
            documentation.nixos.enable = false;

            hardware.bluetooth.enable = true;

            programs.dconf.enable = true;

            services.pipewire = {
              enable = true;
              alsa = {
                enable = true;
                support32Bit = true; # this is probably not necessary
              };
              pulse.enable = true;
            };

            # EFI + USB bootable
            isoImage.makeEfiBootable = true;
            isoImage.makeUsbBootable = true;

            isoImage.isoName = "nixos-installer.iso";
            isoImage.appendToMenuLabel = " installer";

            boot.loader.grub.memtest86.enable = true;

            # An installation media cannot tolerate a host config defined file
            # system layout on a fresh machine, before it has been formatted.
            swapDevices = lib.mkImageMediaOverride [ ];
            fileSystems = lib.mkImageMediaOverride config.lib.isoFileSystems;

            # This value determines the NixOS release from which the default
            # settings for stateful data, like file locations and database versions
            # on your system were taken. It‘s perfectly fine and recommended to leave
            # this value at the release version of the first install of this system.
            # Before changing this value read the documentation for this option
            # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
            system.stateVersion = "21.11"; # Did you read the comment?

          })

          home-manager.nixosModule
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.nixos = ({ config, lib, pkgs, ... }: {
                programs.vim = {
                  enable = true;

                  plugins = with pkgs.vimPlugins; [
                    vim-fugitive
                    vim-repeat
                    vim-nix
                  ];

                  extraConfig = ''
                    set exrc

                    set relativenumber
                    set number
                    set scrolloff=8
                    set nowrap

                    set nobackup
                    set noswapfile
                    set hidden
                    set noerrorbells
                    set encoding=UTF-8

                    set smartindent
                    set tabstop=4 softtabstop=4

                    set ttyfast
                    set lazyredraw
                  '';
                };

                programs.zsh = {
                  enable = true;
                  dotDir = ".config/zsh";

                  enableCompletion = true;
                  enableAutosuggestions = true;
                  enableSyntaxHighlighting = true;
                  oh-my-zsh = {
                    enable = true;
                    plugins = [ "git" "vi-mode" ];
                  };

                  initExtra = ''
                    # Enable vi mode
                    bindkey -v
                  '';
                };

                programs.starship = {
                  enable = true;
                  settings = {
                    format = pkgs.lib.concatStrings [
                      "$username"
                      "$hostname"
                      "$directory"
                      "$git_branch"
                      "$git_state"
                      "$git_status"
                      "$cmd_duration"
                      "$line_break"
                      "$jobs"
                      "$battery"
                      "$character"
                    ];
                    cmd_duration = {
                      min_time = 1;
                      format = "in [$duration](bold yellow)";
                    };
                    directory = {
                      truncation_length = 10;
                    };
                    git_branch = {
                      symbol = "";
                      format = "on [$symbol$branch]($style) ";
                    };
                    git_status = {
                      ahead = "⇡$count";
                      diverged = "⇕⇡$ahead_count⇣$behind_count";
                      behind = "⇣$count";
                      modified = "*";
                    };
                    character = {
                      success_symbol = "[λ](bold green)";
                      error_symbol = "[λ](bold red)";
                      vicmd_symbol = "[λ](bold yellow)";
                    };
                  };
                };

                home.file.".local/share/konsole/home-manager.profile".text = ''
                  [General]
                  Name=home-manager
                  Command=zsh
                '';

                home.activation.setDefaultKonsoleProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                  ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file ${config.home.homeDirectory}/.config/konsolerc --group 'Desktop Entry' --key 'DefaultProfile' 'home-manager.profile'
                '';

                home.stateVersion = "21.11";
              });
            };
          }

        ];
      };

    };
}

