{ pkgs, lib, config, ... }:
let
  host = "searx.mbund.org";
  port = 4431;
  name = "searxng";
  user = "thunder-searxng";
  data = "/home/${user}";
in {
  virtualisation.oci-containers.containers.${name} = {
    image = "searxng/searxng";
    environment = {
      BASE_URL = "https://${host}";
      INSTANCE_NAME = "mearxng";
    };
    volumes = [
      "${data}/${name}-container:/etc/searxng"
    ];
    ports = [
      "127.0.0.1:${builtins.toString port}:8080"
    ];
    extraOptions = [ "--network=searxng-br" ];
  };

  systemd.services.init-searxng-network-and-files = {
    description = "Create the network bridge searxng-br for searxng.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script =
      let
        backend = config.virtualisation.oci-containers.backend;
        cli = "${config.virtualisation.${backend}.package}/bin/${backend}";
      in ''
        ${cli} network ls | grep searxng-br || ${cli} network create searxng-br
      '';
  };

  systemd.tmpfiles.rules = [
    "v ${data}/${name}-container 007 ${user} ${user} - -"
  ];

  users.users.${user} = {
    group = user;
    home = data;
    createHome = true;
    isSystemUser = true;
  };

  users.groups.${user} = {
    members = [ "${user}" ];
  };

}
