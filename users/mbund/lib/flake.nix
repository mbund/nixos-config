{
  description = "Common functions";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachSystem ["x86_64-linux"] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Figures out a valid Nix store name for the given path.
        storeFileName = path:
          let
            # All characters that are considered safe. Note "-" is not
            # included to avoid "-" followed by digit being interpreted as a
            # version.
            safeChars = [ "+" "." "_" "?" "=" ] ++ nixpkgs.lib.lowerChars ++ nixpkgs.lib.upperChars
              ++ nixpkgs.lib.stringToCharacters "01234567689";

            empties = l: nixpkgs.lib.genList (x: "") (nixpkgs.lib.length l);

            unsafeInName =
              nixpkgs.lib.stringToCharacters (nixpkgs.lib.replaceStrings safeChars (empties safeChars) path);

            safeName = nixpkgs.lib.replaceStrings unsafeInName (empties unsafeInName) path;
          in "home_" + safeName;
      in {
        lib = {

          # Taken from home-manager
          mkOutOfStoreSymlink = path:
            let
              pathStr = builtins.toString path;
              name = storeFileName (builtins.baseNameOf pathStr);
            in
              pkgs.runCommandLocal name {} ''ln -s ${nixpkgs.lib.escapeShellArg pathStr} $out'';
        };
      }
    );
}