inputs: final: prev:
let
  inherit (final) system;
in
{
  nix-direnv = inputs.nix-direnv.packages.default.${system};
  helix = inputs.helix-editor.packages.default.${system};
}
