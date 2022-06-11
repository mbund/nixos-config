{ pkgs, lib, config, ... }:
let
  port = 4433;
  user = "thunder-mqtt";
  data = "/home/${user}";
in
{
  virtualisation.oci-containers.containers.mosquitto = {
    image = "eclipse-mosquitto:2";
    volumes = [
      "${data}/mosquitto-container/config:/mosquitto/config"
      "${data}/mosquitto-container/data:/mosquitto/data"
      "${data}/mosquitto-container/log:/mosquitto/log"
    ];
    ports = [
      "127.0.0.1:9002:9001"
    ];
    extraOptions = [ "--network=mqtt-br" ];
  };

  virtualisation.oci-containers.containers.nodered = {
    image = "nodered/node-red:latest-12";
    volumes = [
      "${data}/nodered-container/data:/data"
    ];
    ports = [
      "127.0.0.1:1880:1880"
    ];
    dependsOn = [ "mosquitto" ];
    extraOptions = [ "--network=mqtt-br" ];
  };

  systemd.services.init-mqtt-network-and-files = {
    description = "Create the network bridge mqtt-br for mqtt.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script =
      let
        backend = config.virtualisation.oci-containers.backend;
        cli = "${config.virtualisation.${backend}.package}/bin/${backend}";
      in ''
        ${cli} network ls | grep mqtt-br || ${cli} network create mqtt-br
      '';
  };

  systemd.tmpfiles.rules = [
    "v ${data}/nodered-container                777 ${user} ${user} - -"
    "v ${data}/nodered-container/data           777 ${user} ${user} - -"

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
