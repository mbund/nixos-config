{ config, pkgs, ... }:

{
  home.pkgs = with pkgs; [
    git
    neovim
    
    home-manager
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "21.11";
}