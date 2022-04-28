{
  description = "System configurations for custom desktop environment";

  outputs = { self, ... }@inputs: {
    nixosModule = { pkgs, config, lib, ... }: let
      cfg = config.services.custom-desktop-environment;
    in {

      options.services.custom-desktop-environment = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = ''
            Whether or not to enable the custom desktop environment.
          '';
        };

        login-manager = {
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
      };

      config = lib.mkIf cfg.enable {

        xdg.portal = {
          enable = true;
          wlr = {
            enable = true;
          };
          gtkUsePortal = true;
        };

        hardware.opengl.enable = true;
        programs.xwayland.enable = true;
        programs.dconf.enable = true;
        services.pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true; # this is probably not necessary
          };
          pulse.enable = true;
        };

      };

    };
  };
}
