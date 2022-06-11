{ pkgs, lib, config, ... }:
let
  port = 6167;
  user = "thunder-matrix";
  data = "/home/${user}";
in
{
  virtualisation.oci-containers.containers.matrixdendrite = {
    image = "matrixdotorg/dendrite-monolith:v0.8.8";
    volumes = [
      "${data}/dendrite-container/config:/etc/dendrite"
      "${data}/dendrite-container/media:/var/dendrite/media"
    ];
    ports = [
      "127.0.0.1:8009:8008"
      "127.0.0.1:8449:8448"
    ];
    dependsOn = [ "matrixpostgres" ];
    extraOptions = [ "--network=matrix-br" ];
    # cmd = [ "-really-enable-open-registration" ];
  };

  virtualisation.oci-containers.containers.matrixpostgres = {
    image = "postgres:14.3";
    environment = {
      POSTGRES_USER = "dendrite";
      POSTGRES_PASSWORD_FILE = "/run/secrets/matrix-postgres-password";
      PGDATA = "/var/lib/postgresql/data/pgdata";
    };
    volumes = [
      "${builtins.toFile "create-db.sh" ''
          #!/usr/bin/env bash

          for db in userapi_accounts mediaapi syncapi roomserver keyserver federationapi appservice mscs; do
              createdb -U dendrite -O dendrite dendrite_$db
          done
      ''}:/docker-entrypoint-initdb.d/create-db.sh"
      "${data}/postgres-container/data:/var/lib/postgresql/data"

      "/etc/secrets/matrix-postgres-password:/run/secrets/matrix-postgres-password"
    ];
    extraOptions = [ "--network=matrix-br" ];
  };

  systemd.services.init-matrix-network-and-files = {
    description = "Create the network bridge matrix-br for matrix.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script =
      let
        backend = config.virtualisation.oci-containers.backend;
        cli = "${config.virtualisation.${backend}.package}/bin/${backend}";
      in ''
        ${cli} network ls | grep matrix-br || ${cli} network create matrix-br
      '';
  };

  systemd.tmpfiles.rules = [
    "v ${data}/dendrite-container        777 ${user} ${user} - -"
    "v ${data}/dendrite-container/config 777 ${user} ${user} - -"
    "v ${data}/dendrite-container/media  777 ${user} ${user} - -"
    "v ${data}/postgres-container        777 ${user} ${user} - -"
    "v ${data}/postgres-container/data   777 ${user} ${user} - -"
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
