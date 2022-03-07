![License](https://img.shields.io/github/license/mbund/nixos-config?color=dgreen&style=flat-square) ![Size](https://img.shields.io/github/repo-size/mbund/nixos-config?color=red&label=size&style=flat-square) [![NixOS](https://img.shields.io/badge/NixOS-unstable-9cf.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)  

## About
My NixOS configuration. Check out how I manage my home files [here](https://github.com/mbund/nix-home).

## Philosophy
The only things that should be configured here are system-wide or root-only actions. System services, permissions, bootloader, etc. but very rarely packages.

## Structure
All of my systems that run NixOS are in one repository, and are all referenced from the root flake. Each individual system is a sub-flake defining their `nixosConfigurations`.

## Install
Take a look at my [modern nix guide for full installation instructions](https://github.com/mbund/modern-nix-guide/wiki/Installation). You'll probably want to use [my installer ISO](https://github.com/mbund/nixos-config/releases) or [make your own](https://github.com/mbund/nixos-config#custom-iso). You can find the exact shell commands that I used to generate each of my systems by each `install.sh` file you can find, for example `desktop/install.sh` is how my current desktop was installed. Note that I am still learning myself and the exact way that I installed my current systems is flawed, so you should really consult the modern nix guide for best practice.

## Custom ISO
If you do not want to use my custom ISO, you can build a custom one yourself. Here are some reasons why you might want to do that.

- Custom kernel. One of the reasons for me distributing my ISO is shipping with a more up-to-date kernel for maximum hardware compatibility. However your system may be incompatible with the latest kernel or it might require some patches, for example. If you know your system will have issues running on the latest kernel, you should follow these steps. If you don't know what I'm talking about here, then you should be fine using my ISO.
- Security. My ISO is actually built from continuous integration and automatically released, but if you still feel uncomfortable using, you can build it from source.

With Nix already installed, it would look something like this:
```
git clone https://github.com/mbund/nixos-config
cd nixos-config
# make your edits to `nixos-installer/flake.nix`, changing `boot.kernelPackages`, for example

nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
cp result/iso/nixos-installer.iso nixos-installer-$(date +'%F-%H-%M').iso
```
You can now use that ISO as you would any other.
