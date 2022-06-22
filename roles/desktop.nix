{ ... }: {
  imports = [
    ./base.nix

    ../profiles/hyprland-de.nix
    ../profiles/firefox.nix
    ../profiles/gaming.nix
  ];
}