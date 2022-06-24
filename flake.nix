{
  description = "Configuration for all of my machines";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    deploy-rs.url = github:serokell/deploy-rs;
    home-manager.url = github:rycee/home-manager;
    impermanence.url = github:nix-community/impermanence;
    nix-direnv.url = github:nix-community/nix-direnv;
    nur.url = github:nix-community/nur;
    flake-compat = { url = github:edolstra/flake-compat; flake = false; };
    helix-editor.url = github:helix-editor/helix;
    hyprland.url = github:vaxerski/hyprland;
    agenix.url = github:ryantm/agenix;
    utils.url = github:numtide/flake-utils;
  };

  outputs = { nixpkgs, self, utils, deploy-rs, ... }@inputs:
    let
      pkgsFor = system: import nixpkgs {
        overlays = with inputs; [
          self.overlays.default
          hyprland.overlays.default
        ];
        localSystem = { inherit system; };
      };

      mkSystem = system: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = with inputs; [
          nur.nixosModules.nur
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          hyprland.nixosModules.default
          agenix.nixosModules.age
        ] ++ extraModules;
      };
    in
    {
      overlays.default = builtins.import ./overlay.nix inputs;

      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      # nixosConfigurations.kuro = mkSystem "x86_64-linux" [ ./hosts/kuro ];
      # deploy.nodes.kuro = {
      #   hostname = "192.168.1.115";
      #   profiles.system = {
      #     user = "root";
      #     path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.kuro;
      #   };
      # };

      # nixosConfigurations.kodai = mkSystem "x86_64-linux" [ ./hosts/kodai ];
      # deploy.nodes.kodai = {
      #   hostname = "192.168.1.103";
      #   profiles.system = {
      #     user = "root";
      #     path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.kodai;
      #   };
      # };

      nixosConfigurations.marshmellow-roaster = mkSystem "x86_64-linux" [ ./hosts/marshmellow-roaster ];
      deploy.nodes.marshmellow-roaster = {
        hostname = "192.168.1.122";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.marshmellow-roaster;
        };
      };

    } // utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rnix-lsp
            nixpkgs-fmt
            inputs.deploy-rs.packages.${system}.deploy-rs
            inputs.agenix.packages.${system}.agenix
          ];
        };
        apps.default = deploy-rs.apps.${system}.default;
      }
    );
}
