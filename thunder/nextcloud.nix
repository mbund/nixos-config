{ pkgs, lib, config, ... }:
let
  port = 4432;
  user = "thunder-nextcloud";
  data = "/home/${user}";
in
{
  # edit nextcloud's config.php and add
  # 'overwritehost' => 'nextcloud.mbund.org',
  # 'overwriteprotocol' => 'https',

  virtualisation.oci-containers.containers.nextcloud = {
    image = "nextcloud";
    environment = {
      MYSQL_DATABASE = "nextcloud";
      MYSQL_USER = "nextcloud";
      MYSQL_HOST = "nextcloudmariadb:3306";
      NEXTCLOUD_ADMIN_USER = "admin";
        
      MYSQL_PASSWORD_FILE = "/run/secrets/nextcloud-mariadb-password";
      NEXTCLOUD_ADMIN_PASSWORD_FILE = "/run/secrets/nextcloud-admin-password";
    };
    volumes = [
      "${data}/nextcloud-container/nextcloud:/var/www/html"
      "${data}/nextcloud-container/apps:/var/www/custom_apps"
      "${data}/nextcloud-container/config:/var/www/config"
      "${data}/nextcloud-container/data:/var/www/data"
      
      "/etc/secrets/nextcloud-mariadb-password:/run/secrets/nextcloud-mariadb-password"
      "/etc/secrets/nextcloud-admin-password:/run/secrets/nextcloud-admin-password"
    ];
    ports = [
      "127.0.0.1:${builtins.toString port}:80"
    ];
    dependsOn = [ "nextcloudmariadb" ];
    extraOptions = [ "--network=nextcloud-br" ];
  };

  virtualisation.oci-containers.containers.nextcloudmariadb = {
    image = "mariadb";
    environment = {
      MARIADB_DATABASE = "nextcloud";
      MARIADB_USER = "nextcloud";

      MARIADB_ROOT_PASSWORD_FILE = "/run/secrets/nextcloud-mariadb-root-password";
      MARIADB_PASSWORD_FILE = "/run/secrets/nextcloud-mariadb-password";
    };
    volumes = [
      "${data}/nextcloudmariadb-container/data:/var/lib/mysql"

      "/etc/secrets/nextcloud-mariadb-password:/run/secrets/nextcloud-mariadb-password"
      "/etc/secrets/nextcloud-mariadb-root-password:/run/secrets/nextcloud-mariadb-root-password"
      "/etc/secrets/nextcloud-admin-password:/run/secrets/nextcloud-admin-password"
    ];
    extraOptions = [ "--network=nextcloud-br" ];
  };
    
  virtualisation.oci-containers.containers.onlyofficedocumentserver = {
    image = "onlyoffice/documentserver";
    volumes = [
      "${data}/onlyofficedocumentserver-container/logs:/var/log/onlyoffice"
      "${data}/onlyofficedocumentserver-container/data:/var/www/onlyoffice/Data"
      "${data}/onlyofficedocumentserver-container/lib:/var/lib/onlyoffice"
      "${data}/onlyofficedocumentserver-container/rabbitmq:/var/lib/rabbitmq"
      "${data}/onlyofficedocumentserver-container/redis:/var/lib/redis"
      "${data}/onlyofficedocumentserver-container/db:/var/lib/postgresql"
    ];
    ports = [
      "127.0.0.1:4433:80"
    ];
    extraOptions = [ "--network=nextcloud-br" ];
  };

  systemd.services.init-nextcloud-network-and-files = {
    description = "Create the network bridge nextcloud-br for nextcloud.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script =
      let
        backend = config.virtualisation.oci-containers.backend;
        cli = "${config.virtualisation.${backend}.package}/bin/${backend}";
      in ''
        ${cli} network ls | grep nextcloud-br || ${cli} network create nextcloud-br
      '';
  };

  systemd.tmpfiles.rules = [
    "v ${data}/nextcloud-container                         777 ${user} ${user} - -"
    "v ${data}/nextcloud-container/nextcloud               777 ${user} ${user} - -"
    "v ${data}/nextcloud-container/apps                    777 ${user} ${user} - -"
    "v ${data}/nextcloud-container/config                  777 ${user} ${user} - -"
    "v ${data}/nextcloud-container/data                    777 ${user} ${user} - -"

    "v ${data}/nextcloudmariadb-container                  777 ${user} ${user} - -"
    "v ${data}/nextcloudmariadb-container/data             777 ${user} ${user} - -"

    "v ${data}/onlyofficedocumentserver-container          777 ${user} ${user} - -"
    "v ${data}/onlyofficedocumentserver-container/logs     777 ${user} ${user} - -"
    "v ${data}/onlyofficedocumentserver-container/data     777 ${user} ${user} - -"
    "v ${data}/onlyofficedocumentserver-container/lib      777 ${user} ${user} - -"
    "v ${data}/onlyofficedocumentserver-container/rabbitmq 777 ${user} ${user} - -"
    "v ${data}/onlyofficedocumentserver-container/redis    777 ${user} ${user} - -"
    "v ${data}/onlyofficedocumentserver-container/db       777 ${user} ${user} - -"
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
