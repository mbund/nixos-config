{
  description = "Configuration for all of my machines";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    deploy-rs.url = github:serokell/deploy-rs;
    home-manager.url = github:rycee/home-manager;
    impermanence.url = github:nix-community/impermanence;
    nix-direnv.url = github:nix-community/nix-direnv;
    nur = { url = github:nix-community/nur; flake = false; };
    flake-compat = { url = github:edolstra/flake-compat; flake = false; };
    helix-editor.url = github:helix-editor/helix;
    hyprland.url = github:vaxerski/hyprland;
    agenix.url = github:ryantm/agenix;
    utils.url = github:numtide/flake-utils;
  };

  outputs = { nixpkgs, self, utils, deploy-rs, ... }@inputs:
    let
      findModules = dir:
        builtins.concatLists (builtins.attrValues (builtins.mapAttrs
          (name: type:
            if type == "regular" then [{
              name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
              value = dir + "/${name}";
            }] else if (builtins.readDir (dir + "/${name}"))
              ? "default.nix" then [{
              inherit name;
              value = dir + "/${name}";
            }] else
              findModules (dir + "/${name}"))
          (builtins.readDir dir)));

      pkgsFor = system: import nixpkgs {
        overlays = with inputs; [
          self.overlays.default
          hyprland.overlays.default
          nur.overlay
        ];
        localSystem = { inherit system; };
      };

      mkSystem = system: extraModules: nixpkgs.lib.nixosSystem rec {
        inherit system;
        modules = [
          inputs.agenix.nixosModules.age
          inputs.home-manager.nixosModules.home-manager
          ({ config, ... }: {
            system.configurationRevision = self.sourceInfo.rev;
            services.getty.greetingLine =
              "<<< Welcome to NixOS ${config.system.nixos.label} @ ${self.sourceInfo.rev} - \\l >>>";
            
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          })
        ] ++ extraModules;
      };
      
      mkDeploy = hostname: configuration: {
        inherit hostname;
        sshUser = "root";
        
        profiles.system = {
          user = "root";
          path = deploy-nixos configuration;
        };
      };
      
      deploy-nixos = configuration: deploy-rs.lib.${configuration.pkgs.system}.active.nixos configuration;
    in
    {
      nixosModules = builtins.listToAttrs (findModules ./modules);
      nixosProfiles = builtins.listToAttrs (findModules ./profiles);
      nixosRoles = import ./roles;
      overlays.default = import ./overlay.nix inputs;

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      
      nixosConfigurations.kuro = mkSystem "x86_64-linux" [ ./hosts/kuro ];
      deploy.nodes.kuro = mkDeploy "192.168.1.115" self.nixosConfigurations.kuro;

      nixosConfigurations.kodai = mkSystem "x86_64-linux" [ ./hosts/kodai ];
      deploy.nodes.kodai = mkDeploy "192.168.1.103" self.nixosConfigurations.kodai;

    } // utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rnix-lsp
            nixfmt
            deploy-rs.packages.${system}.deploy-rs
            agenix.packages.${system}.agenix
          ];
        };
        apps.default = deploy-rs.apps.default;

        packages.pin-global-registry = pkgs.writeShellApplication {
          name = "pin-global-registry";
          runtimeInputs = with pkgs; [ jq ];
          text = builtins.readFile ./pin-global-registry.sh;
        };
      }
    );
}
