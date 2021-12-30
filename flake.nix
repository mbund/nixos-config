{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
  };

  outputs = { self, virtualbox }:
  {
    nixosConfigurations = virtualbox.nixosConfigurations \\ marshmellow-roaster;
  };
}