{ pkgs, ... }: {
  imports = [
    ../modules/persist.nix
    
    ../profiles/security.nix
    ../profiles/nix.nix
    ../profiles/git.nix
    ../profiles/zsh.nix
    ../profiles/helix.nix
  ];
  
  environment.systemPackages = with pkgs; [
    git vim curl wget
  ];
}