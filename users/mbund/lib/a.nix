{ pkgs ? import <nixpkgs> { } }:
let
  # pkgs = import nixpkgs { inherit system; };
  lib = pkgs.lib;

  # Figures out a valid Nix store name for the given path.
  storeFileName = path:
    let
      # All characters that are considered safe. Note "-" is not
      # included to avoid "-" followed by digit being interpreted as a
      # version.
      safeChars = [ "+" "." "_" "?" "=" ] ++ lib.lowerChars ++ lib.upperChars
        ++ lib.stringToCharacters "01234567689";

      empties = l: lib.genList (x: "") (lib.length l);

      unsafeInName =
        lib.stringToCharacters (lib.replaceStrings safeChars (empties safeChars) path);

      safeName = lib.replaceStrings unsafeInName (empties unsafeInName) path;
    in "home_" + safeName;
in {
  lib = {

    # Taken from home-manager
    symlink = path:
      let
        pathStr = builtins.toString path;
        name = storeFileName (builtins.baseNameOf pathStr);
      in
        pkgs.runCommandLocal name {} ''ln -s ${lib.escapeShellArg pathStr} $out'';
  };
}