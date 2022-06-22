{ pkgs, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
  ];

  hardware.nvidia.modesetting.enable = true;
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };
  
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = 1;
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];

    deviceSection = ''
      Option "AllowSHMPixmaps" "on"
      Option "DRI3" "on"
    '';
  };
}
