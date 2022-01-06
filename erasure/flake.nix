{

  description = "NixOS opt in state, erasure on boot";

  outputs = { self }: {
    nixosModule = { pkgs, config, lib, ... }: {
      options = {
        environment.erasure = lib.mkOption {
          default = { };

          type = lib.types.attrsOf (
            lib.types.submodule ({ name, ... }: {
              options = {
#                enable = lib.mkOption {
#                  type = lib.types.bool;
#                  default = true;
#                  description = ''
#                    Whether to enable erasure or not. 
#                  '';
#                };

                btrfs = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Enable if using `btrfs` as root.
                    '';
                  };

                  root-subvolume = lib.mkOption {
                    type = lib.types.str;
                    example = "root";
                    description = ''
                       `btrfs` subvolume which will be rolled back on boot. Should be the subvolume mounted on to `/`.
                    '';
                  };

                  root-rollback-snapshot = lib.mkOption {
                    type = lib.types.str;
                    example = "root-blank";
                    description = ''
                      `btrfs` snapshot to roll back to on boot. Ideally should be a read-only snapshot taken while completely blank.
                    '';
                  };
                };

                tmpfs = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Enable if using `tmpfs` as root.
                    '';
                  };
                };

                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  example = [
                    "/etc/nixos"
                    "/etc/machine-id"
                  ];
                  description = ''
                    Files and folders that should be put into persistent storage.
                  '';
                };

                ignore = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  example = [
                    "/tmp/*"
                  ];
                  description = ''
                    Regex per line of paths that should be ignored when running `filesystem-diff`.
                  '';
                };
              };
            })
          );

          description = ''
            Persistent storage locations and the paths to link them. Each attribute name should be the full path to a persistant storage location.
          '';
        };
      };

      config = (lib.mkIf config.environment.persistence != {})
        map (x: let
          persist = config.environment.persistence.${x};
        in {        
          system.activationScripts.erasure = ''
            echo "This is brought to you by stdout"
            >&2 echo "This is brought to you by stderr"
          '';
        }) config.environment.persistence; 
    };
  };

}
