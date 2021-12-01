{ pkgs, lib, config, ... }:
{
  options = {
    deviceName = lib.mkOption { type = lib.types.str; };
  };
}