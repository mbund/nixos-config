{ pkgs, lib, config, ... }:
let
  port = 4432;
  user = "thunder-nextcloud";
  uid = 10002;
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
        
      MYSQL_PASSWORD_FILE = "/run/secrets/nextcloud-mariadb-password";
      NEXTCLOUD_ADMIN_PASSWORD_FILE = "/run/secrets/nextcloud-admin-password";
    };
    volumes = [
      "${data}/nextcloud-container/nextcloud:/var/www/html"
      "${data}/nextcloud-container/apps:/var/www/custom_apps"
      "${data}/nextcloud-container/config:/var/www/config"
      "${data}/nextcloud-container/data:/var/www/data"
      
      "${localfile "secrets/nextcloud-mariadb-password"}:/run/secrets/nextcloud-mariadb-password"
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

      MARIADB_ROOT_PASSWORD_FILE = "/run/secrets/nextcloud-mariadb-root-password";
      MARIADB_PASSWORD_FILE = "/run/secrets/nextcloud-mariadb-password";
    };
    volumes = [
      "${data}/nextcloudmariadb-container/data:/var/lib/mysql"

      "${localfile "secrets/nextcloud-mariadb-password"}:/run/secrets/nextcloud-mariadb-password"
      "${localfile "secrets/nextcloud-mariadb-root-password"}:/run/secrets/nextcloud-mariadb-root-password"
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
    "v ${data}/nextcloud-container             550 ${user} ${user} - -"
    "v ${data}/nextcloud-container/nextcloud   550 ${user} ${user} - -"
    "v ${data}/nextcloud-container/apps        550 ${user} ${user} - -"
    "v ${data}/nextcloud-container/config      550 ${user} ${user} - -"
    "v ${data}/nextcloud-container/data        550 ${user} ${user} - -"
    "v ${data}/nextcloudmariadb-container      550 ${user} ${user} - -"
    "v ${data}/nextcloudmariadb-container/data 550 ${user} ${user} - -"
  ];

  users.users.${user} = {
    group = user;
    home = data;
    createHome = true;
    isSystemUser = true;
    inherit uid;
  };

  users.groups.${user} = {
    members = [ "${user}" ];
    gid = uid;
  };

}
