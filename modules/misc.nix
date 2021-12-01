{ pkgs, lib, config, inputs, ... }: {
  home-manager.users.mbund = {
    home.stateVersion = "21.11";
  };

  system.stateVersion = "21.11";
}