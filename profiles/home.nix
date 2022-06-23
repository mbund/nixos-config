{ ... }:
let
  home = {
    xdg.userDirs = {
      enable = true;
      desktop = "$HOME/data/desktop";
      documents = "$HOME/data/documents";
      download = "$HOME/data/downloads";
      music = "$HOME/data/music";
      pictures = "$HOME/data/pictures";
      publicShare = "$HOME/data/public";
      templates = "$HOME/data/templates";
      videos = "$HOME/data/videos";
    };

    # remove all files ending with .hm-remove
    # useful for `home-manager switch -b hm-remove` when you don't care about overwriting
    home.activation.removeOverwrite = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD find ${config.home.homeDirectory} -type f -name "*.hm-remove" -exec rm {} \;
    '';

    programs.home-manager.enable = true;
  };
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.mbund = home;
}
