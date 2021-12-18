{
  description = "Virtualbox NixOS Configuration";

  # allow the experimental nix commands and flakes system wide
  nixConfig.extra-experimental-features = "nix-command flakes sdasdsfas";

  
  nixConfig.extra-options = "keep-outputs keep-derivations";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  {
    nixosConfigurations.virtualbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}