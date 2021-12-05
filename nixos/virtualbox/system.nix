{ pkgs, inputs, lib, ... }@extra: {

  nixpkgs.overlays = [

        (self: super: {
          awesome = super.awesome.overrideAttrs (oldAttrs: rec {
            src = super.fetchFromGitHub {
              owner = "awesomeWM";
              repo = "awesome";
              rev = "e7a21947e6785f53042338c684b9b96cc9b0f500";
              sha256 = "1494902ma51nzhhxg35cbl2lp9r8hwin2f2n7d1ag3m7n0ql6nk8";
            };
          });
        })

      ];

  imports = [
    ./hardware-configuration.nix
    
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.mbund = ((import ./home.nix) extra);
    }
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