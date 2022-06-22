{ config, pkgs, lib, ... }: {
  security.apparmor.enable = true;
  programs.firejail.enable = true;

  users.mutableUsers = false;
  
  # nixos configuration storage
  users.groups.nixos-configurator = { };
  systemd.tmpfiles.rules = [
    "Z /etc/nixos 775 root nixos-configurator - -"
  ];
  
  # manage root user
  users.users.root = {
    password = "root";
  };

  # create user and group `mbund`
  users.groups.mbund = { };
  users.users.mbund = {
    isNormalUser = true;
    group = "mbund";
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
      "video"
      "render"

      "users"
      "doas"
      "nixos-configurator"

      "networkmanager"
    ];
    uid = 1000;
    password = "mbund";
  };

  # privilege escalation
  security.sudo.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [
    { groups = [ "doas" ]; noPass = false; keepEnv = true; }
  ];

}
