{

  description = "Gnome based desktop environment";

  outputs = { ... }@inputs: {
    nixosModule = { pkgs, config, lib, ... }:
      let
        cfg = config.services.mbund-gnome;
      in
      {
        options.services.mbund-gnome = {
          enable = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = ''
              Whether or not to enable my gnome based custom desktop environment.
            '';
          };
        };

        config = lib.mkIf cfg.enable {
          services.xserver = {
            enable = true;

            displayManager.gdm = {
              enable = true;
              wayland = true;
            };

            desktopManager.gnome.enable = true;
          };

          # Gnome extensions and configuration
          services.gnome.chrome-gnome-shell.enable = true;
          programs.dconf.enable = true;
          programs.kdeconnect = {
            enable = true;
            package = pkgs.gnomeExtensions.gsconnect;
          };
          services.gnome.gnome-keyring.enable = true;
          programs.seahorse.enable = true;
          security.pam.services.login = {
            enableGnomeKeyring = true;
          };

          # Multimedia
          hardware.bluetooth.enable = true;
          services.xserver.wacom.enable = true;
          hardware.pulseaudio.enable = lib.mkForce false;
          xdg.portal.gtkUsePortal = true;        
          services.pipewire = {
            enable = true;
            alsa = {
              enable = true;
              support32Bit = true; # this is probably not necessary
            };
            pulse.enable = true;
            jack.enable = true;
          };
          boot.kernelModules = [ "v4l2loopback" ];
          boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];          

        };
      };
  };
}
