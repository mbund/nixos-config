{ pkgs, lib, config, ... }:
let
  port = 4432;
  user = "thunder-nextcloud";
  data = "/home/${user}";
  localfile = path: "/etc/nixos/thunder/" + path;
in
{
  # edit nextcloud's config.php and add
  # 'overwritehost' => 'nextcloud.mbund.org',

  virtualisation.oci-containers.containers.nextcloud = {
    image = "nextcloud";
    environment = {
      MYSQL_DATABASE = "nextcloud";
      MYSQL_USER = "nextcloud";
      MYSQL_HOST = "nextcloudmariadb:3306";
      NEXTCLOUD_ADMIN_USER = "admin";
        
      MYSQL_PASSWORD_FILE = "/run/secrets/mariadb-password";
      NEXTCLOUD_ADMIN_PASSWORD_FILE = "/run/secrets/nextcloud-admin-password";
    };
    volumes = [
      "${data}/nextcloud-container/nextcloud:/var/www/html"
      "${data}/nextcloud-container/apps:/var/www/custom_apps"
      "${data}/nextcloud-container/config:/var/www/config"
      "${data}/nextcloud-container/data:/var/www/data"
      
      "${localfile "secrets/mariadb-password"}:/run/secrets/mariadb-password"
      "${localfile "secrets/nextcloud-admin-password"}:/run/secrets/nextcloud-admin-password"
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

      MARIADB_ROOT_PASSWORD_FILE = "/run/secrets/mariadb-root-password";
      MARIADB_PASSWORD_FILE = "/run/secrets/mariadb-password";
    };
    volumes = [
      "${data}/nextcloudmariadb-container/data:/var/lib/mysql"

      "${localfile "secrets/mariadb-password"}:/run/secrets/mariadb-password"
      "${localfile "secrets/mariadb-root-password"}:/run/secrets/mariadb-root-password"
      "${localfile "secrets/nextcloud-admin-password"}:/run/secrets/nextcloud-admin-password"
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
    "v ${data}/nextcloud-container                 755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/nextcloud       755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/apps            755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/config          755 ${user} ${user} - -"
    "v ${data}/nextcloud-container/data            755 ${user} ${user} - -"
    "v ${data}/nextcloudmariadb-container          755 ${user} ${user} - -"
    "v ${data}/nextcloudmariadb-container/data     755 ${user} ${user} - -"
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
