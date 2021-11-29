{ pkgs, lib, inputs, ... }: {
  nix = {
    trustedUsers = [ "mbund" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # registry.np.flake = inputs.nixpkgs;
  environment.etc.nixpkgs.source = inputs.nixpkgs;
  environment.etc.self.source = inputs.self;
}
