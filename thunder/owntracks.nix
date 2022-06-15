{ pkgs, lib, config, ... }:
let
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
