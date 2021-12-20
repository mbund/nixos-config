{ pkgs, ... }: {
  
  imports = [
    ./hardware-configuration.nix
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };

  networking.hostName = "virtualbox";
  time.timeZone = "America/New_York";

  users.users = {
    mbund = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      uid = 1000;
      initialPassword = "mbund";
    };
  };

  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true; # this is probably not necessary
    };
    pulse.enable = true;
  };

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  system.stateVersion = "21.11";

}
