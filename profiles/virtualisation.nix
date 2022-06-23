{ config, pkgs, lib, ... }: let

  home = {
    home.packages = with pkgs; [
        virt-manager
    ];
  };

in {
  virtualisation.docker.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
    qemu.runAsRoot = false;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  home-manager.users.mbund = home;
  
  environment.persist.root.directories = [
    "/var/lib/libvirt"
    "/var/lib/docker"
  ];
}
