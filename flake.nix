{
  description = "NixOS Configuration";

  inputs = {
    virtualbox.url = "./virtualbox";
  };

  outputs = { self, virtualbox }:
  {
    nixosConfigurations = virtualbox.nixosConfigurations;
  };
}