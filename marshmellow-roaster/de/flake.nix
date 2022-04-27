{
  description = "System configurations for custom desktop environment";

  outputs = { self, ... }@inputs: {
    nixosModule = { pkgs, config, lib, ... }: {

      options.services.custom-desktop-environment = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
          options = {

            enable = lib.mkOption {
              default = false;
              type = lib.types.bool;
              description = ''
                Whether or not to enable the custom desktop environment.
              '';
            };

            login-manager = lib.mkOption {
              default = { };
              type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
                options = {

                  enable = lib.mkOption {
                    default = false;
                    type = lib.types.bool;
                    description = ''
                      Whether or not to enable the recommended login manager for the custom desktop environment.
                    '';
                  };

                  default-user = lib.mkOption {
                    example = "mbund";
                    type = lib.types.str;
                    description = ''
                      Username for the default session to log in to.
                    '';
                  };

                };
              }));

            };
          };
        }));
      };

      config = lib.mkIf config.custom-desktop-environment.enable {

        xdg.portal = {
          enable = true;
          wlr = {
            enable = true;
          };
          gtkUsePortal = true;
        };

        services.greetd = lib.mkIf config.custom-desktop-environment.login-manager.enable {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd hikari";
              user = config.custom-desktop-environment.login-manager.default-user;
            };
          };
        };

      };

    };
  };
}
