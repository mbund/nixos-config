{ pkgs, lib, config, ... }:
let
  port = 4432;
  user = "thunder-nextcloud";
  data = "/home/${user}";
  db_port = 10000;
  localfile = path: "/etc/nixos/thunder/" + path;
in {
  virtualisation.oci-containers.containers.nextcloud = {
    image = "nextcloud";
    environment = {
      POSTGRES_DB = "nextcloud";
      POSTGRES_USER = "nextcloud";
      POSTGRES_HOST = "127.0.0.1";
      NEXTCLOUD_ADMIN_USER = "admin";
    };
    environmentFiles = [
      (localfile "/secrets/nextcloud-env")
      (localfile "/secrets/nextcloud-postgres-env")
    ];
    volumes = [
      "${data}/nextcloud-container/nextcloud:/var/www/html"
      "${data}/nextcloud-container/apps:/var/www/custom_apps"
      "${data}/nextcloud-container/config:/var/www/config"
      "${data}/nextcloud-container/data:/var/www/data"
    ];
    ports = [
      "127.0.0.1:${builtins.toString port}:80"
    ];
    dependsOn = [ "nextcloud-postgres" ];
  };

  virtualisation.oci-containers.containers.nextcloud-postgres = {
    image = "postgres";
    environment = {
      POSTGRES_USER = "nextcloud";
    };
    environmentFiles = [
      (localfile "/secrets/nextcloud-postgres-env")
    ];
    volumes = [
      "${data}/nextcloud-postgres-container/data:/var/lib/postgresql/data"
    ];
    ports = [
      "127.0.0.1:${builtins.toString db_port}:5432"
    ];
  };
  
  systemd.tmpfiles.rules = [
    "v ${data}/nextcloud-container                 755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/nextcloud       755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/apps            755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/config          755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/data            755 ${user} ${user} - -"
    "v ${data}/nextcloud-postgres-container        755 ${user} ${user} - -"
    "v ${data}/nextcloud-postgres-container/data   755 ${user} ${user} - -"
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
