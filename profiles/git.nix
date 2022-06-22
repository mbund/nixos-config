{
  home-manager.users.mbund.programs.git = {
    enable = true;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      safe.directory = "/etc/nixos";
    };

    ignores = [
      "*.swp"
      ".direnv/"
      ".envrc"
      ".vscode/"
      ".mygitignore"
    ];
  };
}
