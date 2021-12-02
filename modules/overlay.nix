{ pkgs, config, lib, inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.nur.overlay
  ];
}