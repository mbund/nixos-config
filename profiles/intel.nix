{ pkgs, ... }: {
  services.xserver.videoDrivers = [ "intel" ];
}