{ config, pkgs, lib, ... }: {
  users.users.mbund = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    uid = 1000;
    password = "";
  };
  home-manager.useUserPackages = true;
}