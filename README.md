![License](https://img.shields.io/github/license/mbund/nixos-config?color=dgreen&style=flat-square) ![Size](https://img.shields.io/github/repo-size/mbund/nixos-config?color=red&label=size&style=flat-square) [![NixOS](https://img.shields.io/badge/NixOS-unstable-9cf.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)  

## About
My NixOS configuration. Check out how I manage my home files [here](https://github.com/mbund/nix-home).

## Philosophy
The only things that should be configured here are system-wide or root-only actions. System services, permissions, bootloader, etc. but very rarely packages.

## Structure
All of my systems that run NixOS are in one repository, and are all referenced from the root flake. Each individual system is a sub-flake defining their `nixosConfigurations`.

## Install
TODO: Document installation process

TODO: Explain github actions

TODO: Make install script
