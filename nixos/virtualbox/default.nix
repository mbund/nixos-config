{ pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "virtualbox";
  time.timeZone = "America/New_York";

  services.xserver = {
    enable = true;

    # video
    # videoDrivers = [ "nvidia" ];

    # touchpad
    # libinput.enable = true;

    # keyboard
    layout = "us";
    xkbOptions = "caps:swapescape,compose:ralt";

    # desktop manager
    windowManager.awesome.enable = true;
    displayManager.defaultSession = "none+awesome";
    desktopManager.xterm.enable = false;

    # misc
    serverFlagsSection = ''
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    '';
  };

  users.users.mbund = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    uid = 1000;
    shell = pkgs.zsh;
    password = "mbund";
  };

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  system.stateVersion = "21.11";

}