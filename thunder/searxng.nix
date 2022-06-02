{ pkgs, lib, config, ... }:
let
  host = "127.0.0.1";
  port = 4431;
  name = "searxng";
  user = "searxng";
  data = "/home/${user}";
in {
  virtualisation.oci-containers.containers.${name} = {
    image = "searxng/searxng";
    environment = {
      BASE_URL = "https://localhost";
      INSTANCE_NAME = "msearx";
    };
    volumes = [
      "${data}/${name}-container:/etc/searxng"
    ];
    ports = [
      "${host}:${builtins.toString port}:8080"
    ];
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

  systemd.services."caddy-${name}" = let
    caddy = action: "${pkgs.caddy}/bin/caddy ${action} --config /etc/caddy/searxng.caddyfile --adapter caddyfile";
  in {
    description = "Caddy web server for ${host}:${builtins.toString port}";
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
      # ProtectHome = true;
      ProtectHome = "tmpfs";
      ProtectSystem = "full";
      # ReadWritePaths = data;
      BindReadOnlyPaths = "${pkgs.caddy}";
      BindPaths = data;
      KillMode = "mixed";
      KillSignal = "SIGQUIT";
      TimeoutStopSec = "5s";
    };
  };
}
