{ ... }: {
  imports = [
    ./base.nix

    ../profiles/hyprland-de.nix
    ../profiles/multimedia.nix
    ../profiles/virtualisation.nix
    ../profiles/firefox.nix
    ../profiles/gaming.nix
  ];
}