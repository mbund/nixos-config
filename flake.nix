{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
    desktop.url = "./desktop";
    nixos-installer.url = "./nixos-installer";
  };

  outputs = { self, ... }@inputs: with inputs; {
    nixosConfigurations =
      virtualbox.nixosConfigurations //
      marshmellow-roaster.nixosConfigurations //
      desktop.nixosConfigurations //
      nixos-installer.nixosConfigurations;

  };
}

