{

  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:rycee/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      findModules = dir:
        builtins.concatLists (builtins.attrValues (builtins.mapAttrs
          (name: type:
            if type == "regular" then
              [{
                name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
                value = dir + "/${name}";
              }]
            else if (builtins.readDir (dir + "/${name}"))
            ? "default.nix" then [{
              inherit name;
              value = dir + "/${name}";
            }] else
              findModules (dir + "/${name}")) (builtins.readDir dir)));
    in {
      nixosModules = builtins.listToAttrs (findModules ./modules);

      nixosConfigurations = let
        hosts = builtins.attrNames (builtins.readDir ./nixos);
        rootPath = ./.;
        mkHost = name:
          let systemPath = ./nixos + "/${name}"; in
          nixpkgs.lib.nixosSystem {
            system = builtins.readFile (systemPath + "/system");
            modules = [ (import (systemPath + "/system.nix")) ];
            specialArgs = { inherit inputs systemPath rootPath; };
          };
      in nixpkgs.lib.genAttrs hosts mkHost;
    };
}
