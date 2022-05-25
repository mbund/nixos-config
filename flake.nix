{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
    desktop.url = "./desktop";
    zephyr.url = "./zephyr";
    thunder.url = "./thunder";
    nixos-installer.url = "./nixos-installer";
    mbund-gnome.url = "./mbund-gnome";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils = { url = "github:numtide/flake-utils"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs: with inputs; {
    nixosConfigurations =
      virtualbox.nixosConfigurations //
      marshmellow-roaster.nixosConfigurations //
      desktop.genNixOSConfigurations inputs //
      zephyr.nixosConfigurations //
      thunder.genNixOSConfigurations inputs //
      nixos-installer.nixosConfigurations //
      { };

  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          rnix-lsp
        ];
      };
      
      packages.pin-global-registry = pkgs.writeShellApplication {
        name = "pin-global-registry";
        runtimeInputs = with pkgs; [ jq ];
        text = builtins.readFile ./pin-global-registry.sh;
      };     
    }
  );
}

