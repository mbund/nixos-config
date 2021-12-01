{ pkgs, config, lib, ... }: {
  options = {
      defaultApplications = lib.mkOption {
        type = lib.attrsOf (lib.submodule ({ name, ... }: {
          options = {
            cmd = lib.mkOption { type = lib.types.path; };
            desktop = lib.mkOption { type = lib.types.str; };
          };
        }));
        description = "Preferred applications";
      };

      startupApplications = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        description = "Applications to run on startup";
      };
    };
}