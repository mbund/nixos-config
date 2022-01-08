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

                name = lib.mkOption {
                  default = name;
                  example = "root";
                  type = lib.types.str;
                  description = "Name for this";
                };

                storage-path = lib.mkOption {
                  example = "/persist";
                  type = lib.types.str;
                  description = "Path to symlink everything into";
                };

                btrfs = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Enable if using `btrfs` as root.
                    '';
                  };

                  device = lib.mkOption {
                    type = lib.types.str;
                    example = "/dev/sda1";
                  };

                  mountpoint = lib.mkOption {
                    type = lib.types.str;
                    example = "/";
                  };

                  subvolume = lib.mkOption {
                    type = lib.types.str;
                    example = "root";
                    description = ''
                       `btrfs` subvolume which will be rolled back on boot. Should be the subvolume mounted on to `/`.
                    '';
                  };

                  rollback-snapshot = lib.mkOption {
                    type = lib.types.str;
                    example = "root-blank";
                    description = ''
                      `btrfs` snapshot to roll back to on boot. Ideally should be a read-only snapshot taken while completely blank.
                    '';
                  };

                  rollback-on-boot = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                  };

                  rollback-command = lib.mkOption {
                    type = lib.types.str;
                    default = "rollback-" + name;
                    description = "Enable rolling back at any time by running the command, given this name. If an empty string there will be no command and the only time there is a rollback is dictated by `rollback-on-boot`";
                  };

                  diff-command = lib.mkOption {
                    type = lib.types.str;
                    default = "diff-" + name;
                  };
                };

                other-rollback = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Enable if rolling back using some other method. If it's on `tmpfs`, for example.
                    '';
                  };
                };

                # TODO
                sources = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };

                linked = lib.mkOption {
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
            Persistent storage locations and the paths to link them. Each attribute name should be the full path to a persistent storage location.
          '';
        };
      };

      config = let
        erasures = builtins.attrNames config.environment.erasure;
        foreachErasure = f: map (x: f config.environment.erasure.${x}) erasures;

        # TODO move these into their own library?
        splitPath = paths:
          (builtins.filter
            (s: builtins.typeOf s == "string" && s != "")
            (builtins.concatMap (builtins.split "/") paths)
          );
        
        dirListToPath = dirList: (builtins.concatStringsSep "/" dirList);

        concatPaths = paths:
          let
            prefix = lib.optionalString (lib.hasPrefix "/" (builtins.head paths)) "/";
            path = dirListToPath (splitPath paths);
          in
            prefix + path;

        allLinked = builtins.concatLists (map (x:
          let erasure = config.environment.erasure.${x};
          in map (y: { source = y; destination = concatPaths [ erasure.storage-path y ]; }) erasure.linked
        ) erasures);
        linkScript = lib.traceVal (lib.concatMapStrings (p: "ln --symbolic --force " + p.destination + " " + p.source + "\n") allLinked);
        
      in {
        environment.systemPackages = (map (x: let
          erasure = config.environment.erasure.${x};
          ignorefiles = builtins.toFile ("erasure-ignore-" + erasure.name) (lib.concatMapStrings (x: x + "\n") erasure.ignore);
          linkedfiles = builtins.toFile ("erasure-ignore-linked-" + erasure.name) (lib.concatMapStrings (x: x + "\n") erasure.linked);
          in
          pkgs.writeShellApplication {
            name = erasure.btrfs.diff-command;
            runtimeInputs = with pkgs; [ btrfs-progs coreutils gnused ];
            text = ''
              if [ "$EUID" != 0 ]; then
                  sudo "$0" "$@"
                  exit $?
                fi

                sudo mkdir -p /mnt
                sudo mount -o subvol=${erasure.btrfs.mountpoint} ${erasure.btrfs.device} /mnt

                OLD_TRANSID=$(sudo btrfs subvolume find-new /mnt/${erasure.btrfs.rollback-snapshot} 9999999)
                OLD_TRANSID=''${OLD_TRANSID#transid marker was }

                sudo btrfs subvolume find-new "/mnt/${erasure.btrfs.subvolume}" "$OLD_TRANSID" |
                sed '$d' | # remove last line ("transid marker was...")
                cut -f17- -d' ' | # remove metadata (inode, file offset, len, etc.)
                while read -r line; do echo ${lib.escapeShellArg erasure.btrfs.mountpoint}"''${line}"; done | # prepend mountpoint
                grep -v -f ${ignorefiles} | # ignore ignored paths
                grep -v -f ${linkedfiles} | # ignore persisted paths
                sort |
                uniq |
                while read -r path; do
                  echo "$path"
                done

                umount /mnt
            '';
          }
        ) (builtins.filter (x:
            let erasure = config.environment.erasure.${x}; in
            erasure.btrfs.enable && erasure.btrfs.diff-command != "") erasures));

        system.activationScripts.erasure =
          ''
            ${linkScript}
          '';

      };

    };
  };

}
