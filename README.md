# nixos-config
My NixOS configuration. Check out how I manage my home files [here](https://github.com/mbund/nix-home).

## Philosophy
The only things that should be configured here are system-wide or root-only actions. System services, permissions, bootloader, etc. but very rarely packages.

## Structure
All of my systems that run NixOS are in one repository, and are all referenced from the root flake. Each individual system is a sub-flake defining their `nixosConfigurations`.

## Install
TODO: Document installation process

TODO: Make install script
