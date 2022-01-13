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

	  system.stateVersion = "21.11";

	})
      ];
    };
  };
}
