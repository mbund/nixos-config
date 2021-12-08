{ pkgs, inputs, lib, ... }@extra: {

  # TODO: move this into home-manager
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

    (self: super: {
      adi1090x-plymouth = pkgs.stdenv.mkDerivation rec {
        pname = "adi1090x-plymouth";
        version = "0.0.1";

        src = pkgs.fetchFromGitHub {
        # src = builtins.fetchGit {
          owner = "adi1090x";
          repo = "plymouth-themes";
          rev = "bf2f570bee8e84c5c20caac353cbe1d811a4745f";
          hash = "sha256-VNGvA8ujwjpC2rTVZKrXni2GjfiZk7AgAn4ZB4Baj2k=";
        };

        buildInputs = [
          pkgs.git
        ];

        configurePhase = ''
          mkdir -p $out/share/plymouth/themes/
        '';

        buildPhase = ''
        '';

        installPhase = ''
          cp -r pack_3/lone $out/share/plymouth/themes
          cat pack_3/lone/lone.plymouth | sed  "s@\/usr\/@$out\/@" > $out/share/plymouth/themes/lone/lone.plymouth
        '';
      };
    })

  ];

  imports = [
    ./hardware-configuration.nix
    
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.mbund = import ./home.nix extra;
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

  boot.plymouth = {
    enable = true;
    themePackages = [ pkgs.adi1090x-plymouth ];
    theme = "lone";
  };

  system.stateVersion = "21.11";

}