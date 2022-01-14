{
  description = "Live ISO confiugration";

  inputs = {
    nixpkgs.url = "nixpkgs";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators }:
  {
    defaultPackage.x86_64-linux = nixos-generators.nixosGenerate {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      format = "iso";
      modules = [
        ({ pkgs, ... }: {

	        isoImage.isoName = "mbund-nixos-live.iso";

          nix = {
            package = pkgs.nixUnstable;
	          extraOptions = ''
              # enable the new standalone nix commands
              experimental-features = nix-command flakes
	          '';
	        };

          environment.systemPackages = with pkgs; [
            git cowsay
          ];

	        networking = {
            hostName = "nixos-iso";
	        };

	        time.timeZone = "America/New_York";

	        system = {
            # Auto updating nix config. More useful for embedded systems
            # that we want to change remotely...
            autoUpgrade = {
              enable = false;
              allowReboot = true;
              flake = "github:mbund/nixos-config";
              flags = [
                "--recreate-lock-file"
                "--no-write-lock-file"
                "-L" # print build logs
              ];
              dates = "daily";
            };

            # Copy over full nixos-config to `/var/run/current-system/full-config/`
            # (available to the currently active derivation for safety/debugging)
            extraSystemBuilderCmds = "cp -rf ${./.} $out/full-config";

            # This value determines the NixOS release from which the default
            # settings for stateful data, like file locations and database versions
            # on your system were taken. It‘s perfectly fine and recommended to leave
            # this value at the release version of the first install of this system.
            # Before changing this value read the documentation for this option
            # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
            stateVersion = "21.11"; # Did you read the comment?
          };

	      })
      ];
    };
  };
}
