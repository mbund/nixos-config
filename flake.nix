{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
    marshmellow-roaster.url = "./marshmellow-roaster";
  };

  outputs = { self, virtualbox, marshmellow-roaster }:
  {
    nixosConfigurations = virtualbox.nixosConfigurations // marshmellow-roaster.nixosConfigurations;
  };
}
