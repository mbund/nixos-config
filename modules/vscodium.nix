{ pkgs, ... }: {
  home-manager.users.mbund.programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
  };
}