{ pkgs, config, lib, ... }: {
  # console.font = "Lat2-Terminus16";
  # console.keyMap = "us";

  # environment.sessionVariables = {
  #   XKB_DEFAULT_LAYOUT = "us";
  #   XKB_DEFAULT_OPTIONS = "caps:swapescape,compose:ralt";
  #   LANG = lib.mkForce "en_US.UTF-8";
  # };

  services.xserver = {
    layout = "us";
    xkbOptions = "caps:swapescape,compose:ralt";
  };

  time.timeZone = "America/New_York";
  home-manager.users.mbund = {
    home.file.".XCompose".source = ./compose;
    home.language = let
      en = "en_US.UTF-8";
    in {
      address = en;
      monetary = en;
      paper = en;
      time = en;
      base = en;
    };
  };
}
