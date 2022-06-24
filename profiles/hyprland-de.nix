{ pkgs, config, ... }:
let
  home = {
    home.packages = with pkgs; [
      foot
      mpv
      zathura
      imv
      wl-clipboard
      wob
      brightnessctl
      pamixer
      (rofi-wayland.override (old: rec { plugins = (old.plugins or [ ]) ++ [ rofi-calc rofi-emoji rofi-power-menu ]; }))
      
      xorg.xeyes
    ];

    services.flameshot = {
      enable = true;
      package = (pkgs.symlinkJoin {
        name = "flameshot";
        paths = [ pkgs.flameshot ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/flameshot \
            --set XDG_CURRENT_DESKTOP sway
        '';
      });
    };

    xsession.enable = true;
    xsession.pointerCursor = {
      size = 16;

      package = config.nur.repos.ambroisie.vimix-cursors;
      name = "Vimix-white-cursors";
      # name = "Vimix-cursors";
    };

    home.sessionVariables = {
      # wlroots based wayland compositors read these to set their cursor
      XCURSOR_THEME = config.xsession.pointerCursor.name;
      XCURSOR_SIZE = config.xsession.pointerCursor.size;
    };
  };
in
{

  environment.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [

  ];
}
