inputs: final: prev:
let
  inherit (final) system;
in {
  nix-direnv = inputs.nix-direnv.packages.default.${system};

  helix-master = inputs.helix-editor.packages.default.${system};
}
