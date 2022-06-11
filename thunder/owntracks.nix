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
      OTR_HOST = "mosquitto";
    };
    volumes = [
      "${data}/owntracks-container/recorder-store:/store"
      # "${data}/owntracks-container/config:/config"
    ];
    ports = [
      # "127.0.0.1:4433:8083"
    ];
    dependsOn = [ "mosquitto" ];
    extraOptions = [ "--network=mqtt-br" ];
  };

  systemd.tmpfiles.rules = [
    "v ${data}/owntracks-container                777 ${user} ${user} - -"
    "v ${data}/owntracks-container/recorder-store 777 ${user} ${user} - -"
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
