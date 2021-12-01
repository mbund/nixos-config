{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
    device
    security
    applications
    themes
    nix
    locale
    misc
    fonts

    git
    alacritty
    zsh
    vscodium
    nvim
    plasma
  ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };
}