{ pkgs, lib, config, ... }:
{

  imports = [
    ./caddy-gitlab.nix
  ];

  services.gitlab = rec {
    enable = true;

    host = "gitlab.mbund.org";
    port = 4430;

    # You, dear sysadmin, have to make these files exist.
    initialRootPasswordFile = "/var/lib/gitlab-secrets/initial-password";

    secrets = rec {
      # A file containing 30 "0" characters.
      secretFile = "/var/lib/gitlab-secrets/zeros";
      dbFile = secretFile;
      otpFile = secretFile;
      # openssl genrsa 2048 > jws.rsa
      jwsFile = "/var/lib/gitlab-secrets/jws.rsa";
    };
  };

  services.caddy-gitlab = {
    enable = true;
    config = "/etc/caddy/gitlab.caddyfile";
  };
}
