{ inputs, pkgs, ... }: {
  imports = with inputs.self.nixosModules; with inputs.self.nixosProfiles; [
    inputs.home-manager.nixosModules.home-manager
    
    # modules
    erasure
    
    # profiles
    nix
    git
    zsh
  ];
  
  environment.systemPackages = with pkgs; [
    git vim curl wget
  ];
}