{ config, pkgs, lib, ... }:
let
  home = {
    programs.firefox = {
      enable = true;
      # todo: add arkenfox
      extensions = with config.nur.repos.rycee.firefox-addons; [
        ublock-origin
        skip-redirect
        i-dont-care-about-cookies        
        bitwarden
      ];
    };
  };
in
{
  environment.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
    MOZ_DBUS_REMOTE = "1";
  };

  environment.persist.home.directories = [ "/home/mbund/.mozilla/firefox/default" ];

  home-manager.users.mbund = home;
}
