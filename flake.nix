{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
    desktop.url = "./desktop";
    live-iso.url = "./live-iso";
  };

  outputs = { self, ... }@inputs:
  {
    nixosConfigurations = inputs.virtualbox.nixosConfigurations //
                          inputs.marshmellow-roaster.nixosConfigurations //
                          inputs.desktop.nixosConfigurations //
                          inputs.live-iso.nixosConfigurations;
  };
}
