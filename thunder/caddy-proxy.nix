{ pkgs, lib, config, ... }:
let
  user = "caddy-proxy";
  data = "/home/${user}";
in {
  users.users.${user} = {
    group = user;
    home = data;
    createHome = true;
    isSystemUser = true;
  };

  users.groups.${user} = {
    members = [ "${user}" ];
  };

  systemd.services."caddy-proxy" = let
    caddy = action: "${pkgs.caddy}/bin/caddy ${action} --config /etc/caddy/caddy-proxy.caddyfile --adapter caddyfile";
  in {
    description = "Caddy web proxy";
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
