{ config, pkgs, lib, ... }: {
  hardware.bluetooth.enable = true;

  services.xserver.wacom.enable = true;

  hardware.pulseaudio.enable = lib.mkForce false;
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
}
