{ config, pkgs, lib, ... }:
{
  options.environment.persist = lib.mkOption {
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

          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "/etc/machine-id"
              "/etc/nixos/"
            ];
            description = ''
              Files and folders that should be put into persistent storage.
            '';
          };

          directories = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "/etc/nixos"
            ];
            description = ''
              Folders that should be put into persistent storage.
            '';
          };

          files = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "/etc/machine-id"
            ];
            description = ''
              Files that should be put into persistent storage.
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
  
  config =
    let
      persists = builtins.attrValues config.environment.persist;

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


      # implementation

      packages = lib.flatten (map
        (persist:
          if persist.btrfs.enable && persist.btrfs.diff-command != "" then [
            (pkgs.writeShellApplication {
              name = persist.btrfs.diff-command;
              runtimeInputs = with pkgs; [ btrfs-progs coreutils gnused ];
              text =
                let
                  ignorefiles = builtins.toFile ("persist-ignore-" + persist.name) (lib.concatMapStrings (path: path + "\n") persist.ignore);
                  linkedfiles = builtins.toFile ("persist-ignore-linked-" + persist.name) (lib.concatMapStrings (path: "^" + path + "\n") persist.paths);
                in
                ''
                  if [ "$EUID" != 0 ]; then
                    sudo "$0" "$@"
                    exit $?
                  fi

                  sudo mkdir -p /mnt
                  sudo mount -o subvol=/${persist.btrfs.subvolume} ${persist.btrfs.device} /mnt

                  OLD_TRANSID=$(sudo btrfs subvolume find-new /mnt/${persist.btrfs.rollback-snapshot} 9999999)
                  OLD_TRANSID=''${OLD_TRANSID#transid marker was }

                  sudo btrfs subvolume find-new "/mnt/${persist.btrfs.subvolume}" "$OLD_TRANSID" |
                  sed '$d' | # remove last line ("transid marker was...")
                  cut -f17- -d' ' | # remove metadata (inode, file offset, len, etc.)
                  while read -r line; do echo ${lib.escapeShellArg persist.btrfs.subvolume}"''${line}"; done | # prepend subvolume
                  grep -v -f ${ignorefiles} | # ignore ignored paths
                  grep -v -f ${linkedfiles} | # ignore persisted paths
                  sort |
                  uniq |
                  while read -r path; do
                    if [ -d "$path" ]; then
                      : # ignore if it is a directory
                    else
                      echo "$path"
                    fi
                  done

                  umount /mnt
                '';
            })
          ] else [ ]
        )
        persists);

      postDeviceCommands = builtins.concatStringsSep "\n" (map
        (persist:

          if persist.btrfs.enable && persist.btrfs.rollback-on-boot then ''
            # btrfs state erasure
            # Taken from:
            # https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
            
            mkdir -p /mnt

            # We first mount the btrfs root to /mnt
            # so we can manipulate btrfs subvolumes.
            mount -o subvol=/${persist.btrfs.subvolume} ${persist.btrfs.device} /mnt

            # While we're tempted to just delete /root and create
            # a new snapshot from /root-blank, /root is already
            # populated at this point with a number of subvolumes,
            # which makes `btrfs subvolume delete` fail.
            # So, we remove them first.
            #
            # /root contains subvolumes:
            # - /root/var/lib/portables
            # - /root/var/lib/machines
            #
            # I suspect these are related to systemd-nspawn, but
            # since I don't use it I'm not 100% sure.
            # Anyhow, deleting these subvolumes hasn't resulted
            # in any issues so far, except for fairly
            # benign-looking errors from systemd-tmpfiles.
            btrfs subvolume list -o /mnt/${persist.btrfs.subvolume} |
            cut -f9 -d' ' |
            while read subvolume; do
              echo "deleting /$subvolume subvolume..."
              btrfs subvolume delete "/mnt/$subvolume"
            done &&
            echo "deleting /${persist.btrfs.subvolume} subvolume..." &&
            btrfs subvolume delete /mnt/${persist.btrfs.subvolume}

            echo "restoring blank /${persist.btrfs.subvolume} subvolume..."
            btrfs subvolume snapshot /mnt/${persist.btrfs.rollback-snapshot} /mnt/${persist.btrfs.subvolume}

            # Once we're done rolling back to a blank snapshot,
            # we can unmount /mnt and continue on the boot process.
            umount /mnt
          '' else ""

        )
        persists);

    in
    {
      # Please do not put a lib.traceVal in here. It makes evaluation take like over 5 minutes.
      # This took too long to debug and I don't want to go through that again so heed this warning, future self.

      environment.persistence = builtins.listToAttrs (map
        (persist:
          {
            name = persist.storage-path;
            value = {
              directories = (builtins.filter (path: lib.hasSuffix "/" path) persist.paths) ++ persist.directories;
              files = (builtins.filter (path: ! lib.hasSuffix "/" path) persist.paths) ++ persist.files;
            };
          }
        )
        persists);

      environment.systemPackages = packages;
      boot.initrd.postDeviceCommands = postDeviceCommands;
    };
}
