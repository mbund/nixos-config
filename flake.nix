{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
    iso.url = "./iso";
  };

  outputs = { self, ... }@inputs:
  {
    nixosConfigurations = inputs.virtualbox.nixosConfigurations //
                          inputs.marshmellow-roaster.nixosConfigurations;

    packages.x86_64-linux = {
      iso = inputs.iso.defaultPackage.x86_64-linux;
    };
  };
}
