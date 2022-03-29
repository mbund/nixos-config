{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
    desktop.url = "./desktop";
    zephyr.url = "./zephyr";
    nixos-installer.url = "./nixos-installer";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils = { url = "github:numtide/flake-utils"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs: with inputs; {
    nixosConfigurations =
      virtualbox.nixosConfigurations //
      marshmellow-roaster.nixosConfigurations //
      desktop.nixosConfigurations //
      zephyr.nixosConfigurations //
      nixos-installer.nixosConfigurations //
      { };

  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          rnix-lsp
        ];
      };
    }
  );
}

