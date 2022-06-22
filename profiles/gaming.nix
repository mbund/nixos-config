{ pkgs, lib, ... }:
let

  home = {
    home.packages = with pkgs; [
      minecraft
      (lutris.overrideAttrs (_: { buildInputs = [ xdelta ]; }))
    ];
  };

in
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-runtime"

    "minecraft-launcher"
  ];

  programs.steam.enable = true;

  home-manager.users.mbund = home;
}
