{ pkgs, lib, config, ... }:
let
  user = "caddy-tor";
  data = "/home/${user}";
in
{

  services.tor = {
    enable = true;
    enableGeoIP = false;
    relay.onionServices = {
      thunder = {
        version = 3;
        map = [{
          port = 80;
          target = {
            addr = "127.0.0.1";
            port = 8080;
          };
        }];
      };
    };
    # settings = {
    #   ClientUseIPv4 = false;
    #   ClientUseIPv6 = true;
    #   ClientPreferIPv6ORPort = true;
    # };
  };

  users.users.${user} = {
    group = user;
    home = data;
    createHome = true;
    isSystemUser = true;
  };

  users.groups.${user} = {
    members = [ "${user}" ];
  };

  systemd.services."caddy-tor" =
    let
      caddy = action: "${pkgs.caddy}/bin/caddy ${action} --config /etc/caddy/caddy-tor.caddyfile --adapter caddyfile";
    in
    {
      description = "Caddy tor proxy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      startLimitIntervalSec = 14400;
      startLimitBurst = 10;
      serviceConfig = {
        ExecStart = caddy "run";
        ExecReload = caddy "reload";
        Type = "simple";
        User = user;
        Group = user;
        Restart = "on-abnormal";
        NoNewPrivileges = true;
        LimitNPROC = 512;
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = "tmpfs";
        ProtectSystem = "full";
        BindPaths = data;
        KillMode = "mixed";
        KillSignal = "SIGQUIT";
        TimeoutStopSec = "5s";
      };
    };
}
