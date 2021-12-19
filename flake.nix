{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./systems/virtualbox";
  };

  outputs = { self, virtualbox }:
  {
    nixosConfigurations = virtualbox.nixosConfigurations;
  };
}