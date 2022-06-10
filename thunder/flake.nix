{
  description = "Thunder cloud server configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    genNixOSConfigurations = parentInputs: {
      thunder = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ({ pkgs, config, ... }:
            {

              imports = [
                ./hardware-configuration.nix
                ./networking.nix
                ./caddy-proxy.nix
                ./caddy-tor.nix
                ./searxng.nix
                ./nextcloud.nix
                ./matrix.nix
                ./owntracks.nix
              ];

              nix = {
                settings = {
                  auto-optimise-store = true;
                  trusted-users = [ "root" ];
                  allowed-users = [ "*" ];
                  binary-caches = [
                    "https://cache.nixos.org"
                    "https://nix-community.cachix.org"
                  ];
                  binary-cache-public-keys = [
                    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  ];
                };
                package = pkgs.nixUnstable;
                extraOptions = ''
                  # enable the new standalone nix commands
                  experimental-features = nix-command flakes

                  flake-registry = /etc/nixos/global-flake-registry.json
                  accept-flake-config = true
                  warn-dirty = false
                  
                  # run garbage collection whenever there is less than 500MiB free space left
                  min-free = ${toString (500 * 1024 * 1024)}
                '';
                gc = {
                  automatic = true;
                  dates = "Tuesday 01:00 UTC";
                  options = "--delete-older-than 7d";
                };
              };

              # clear >1 month-old logs
              systemd = {
                services.clear-log = {
                  description = "Clear >1 month-old logs every week";
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=30d";
                  };
                };
                timers.clear-log = {
                  wantedBy = [ "timers.target" ];
                  partOf = [ "clear-log.service" ];
                  timerConfig.OnCalendar = "Tuesday 01:00 UTC";
                };
                tmpfiles.rules = [
                  "v /etc/nixos 775 root nixos-configurator - -"
                ];
              };

              # user options
              users.mutableUsers = false;
              users.groups = {
                # make a new group for the files in /etc/nixos so some users are allowed to edit it
                nixos-configurator = { };
                mbund = { };
              };
              users.users = {
                root.hashedPassword = "*"; # disable root password
                mbund = {
                  isNormalUser = true;
                  group = "mbund";
                  shell = pkgs.zsh;
                  extraGroups = [
                    "users"
                    "wheel"
                    "nixos-configurator"
                    "networkmanager"
                  ];
                  uid = 1000;
                  passwordFile = "/etc/mbund-passwd"; # mkpasswd -m sha-512 > /etc/mbund-passwd
                  openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADcdRDVko8I13btaGgmsg8mE5qxxJlQn8FscTMghdjr mbund@mbund-desktop"
                  ];
                };
              };

              # misc
              virtualisation.docker.enable = true;
              virtualisation.oci-containers.backend = "docker";
              programs.zsh.enable = true;
              time.timeZone = "UTC";
              environment.systemPackages = with pkgs; [
                git
                vim
              ];

              system = {
                autoUpgrade = {
                  enable = true;
                  allowReboot = true;
                  dates = "Daily 01:00 UTC";
                };
                # Copy over full nixos-config to `/var/run/current-system/full-config/`
                # (available to the currently active derivation for safety/debugging)
                extraSystemBuilderCmds = "cp -rf ${./.} $out/full-config";

                # This value determines the NixOS release from which the default
                # settings for stateful data, like file locations and database versions
                # on your system were taken. It‘s perfectly fine and recommended to leave
                # this value at the release version of the first install of this system.
                # Before changing this value read the documentation for this option
                # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
                stateVersion = "22.05"; # Did you read the comment?
              };

            })
        ];
      };
    };
  };
}