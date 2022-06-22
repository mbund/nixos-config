{ pkgs, lib, inputs, config, ... }: let
  
  home = {
    home.packages = with pkgs; [
      nix-index
      nix-tree
      nix-prefetch-scripts
    ];
  };

in {
  nix = {
    nixPath = lib.mkForce [ "self=/etc/self/compat" "nixpkgs=/etc/nixpkgs" ];
    registry.self.flake = inputs.self;
    registry.np.flake = inputs.nixpkgs;

    optimise.automatic = true;
    optimise.dates = [ "03:45" ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    package = pkgs.nixUnstable;

    settings = {
      trusted-users = [ "root" "mbund" "@wheel" ];
      binary-caches = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      binary-cache-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # Copy over full nixos-config to `/var/run/current-system/full-config/`
  # (available to the currently active derivation for safety/debugging)
  system.extraSystemBuilderCmds = "cp -rf ${./.} $out/full-config";

  environment.etc.nixpkgs.source = inputs.nixpkgs;
  environment.etc.self.source = inputs.self;
}
