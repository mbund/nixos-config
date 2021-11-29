{
  home-manager.users.mbund.programs.git = {
    enable = true;
    userEmail = "";
    userName = "";
    extraConfig.pull.rebase = true;
    ignores = [ ".envrc" ".direnv" "*~" ];
    # signing = {
    #   signByDefault = true;
    #   key = "687558B21E04FE92B255BED0E081FF12ADCB4AD5";
    # };
  };
}