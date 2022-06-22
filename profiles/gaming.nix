{ pkgs, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-runtime"
    
    "minecraft-launcher"
  ];
  
  programs.steam.enable = true;
  
  home-manager.users.mbund.packages = with pkgs; [
    minecraft
  ];
}
