{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
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
  ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };
}