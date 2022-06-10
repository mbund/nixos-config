{ pkgs, lib, config, ... }:
let
  port = 4433;
  user = "thunder-owntracks";
  data = "/home/${user}";
in
{
  virtualisation.oci-containers.containers.owntracks = {
    image = "owntracks/recorder";
    environment = {
      OTR_HOST = "owntracksmosquitto";
      OTR_USER = "user";
      OTR_PASS = "pass";
    };
    volumes = [
      "${data}/owntracks-container/recorder-store:/store"
      "${data}/owntracks-container/config:/config"

      "/etc/secrets/owntracks-password:/run/secrets/owntracks-password"
    ];
    ports = [
      "127.0.0.1:${builtins.toString port}:8083"
    ];
    dependsOn = [ "owntracksmosquitto" ];
    extraOptions = [ "--network=owntracks-br" ];
  };

  virtualisation.oci-containers.containers.owntracksmosquitto = {
    image = "eclipse-mosquitto";
    volumes = [
      "${data}/mosquitto-container/config:/mosquitto/config"
      "${data}/mosquitto-container/data:/mosquitto/data"
      "${data}/mosquitto-container/log:/mosquitto/log"
    ];
    extraOptions = [ "--network=owntracks-br" ];
  };

  systemd.services.init-owntracks-network-and-files = {
    description = "Create the network bridge owntracks-br for owntracks.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script =
      let
        backend = config.virtualisation.oci-containers.backend;
        cli = "${config.virtualisation.${backend}.package}/bin/${backend}";
      in ''
        ${cli} network ls | grep owntracks-br || ${cli} network create owntracks-br
      '';
  };

  systemd.tmpfiles.rules = [
    "v ${data}/owntracks-container                777 ${user} ${user} - -"
    "v ${data}/owntracks-container/recorder-store 777 ${user} ${user} - -"
    "v ${data}/mosquitto-container                777 ${user} ${user} - -"
    "v ${data}/mosquitto-container/config         777 ${user} ${user} - -"
    "v ${data}/mosquitto-container/data           777 ${user} ${user} - -"
    "v ${data}/mosquitto-container/log            777 ${user} ${user} - -"
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
