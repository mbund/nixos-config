{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
    live-iso.url = "./live-iso";
  };

  outputs = { self, ... }@inputs:
  {
    nixosConfigurations = inputs.virtualbox.nixosConfigurations //
                          inputs.marshmellow-roaster.nixosConfigurations;

    packages.x86_64-linux = {
      live-iso = inputs.live-iso.defaultPackage.x86_64-linux;
    };
  };
}
