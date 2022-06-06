{ pkgs, lib, config, ... }:
let
  port = 6167;
  user = "thunder-matrix";
  uid = 10003;
  data = "/home/${user}";
  localfile = path: "/etc/nixos/thunder/" + path;
in
{
  # edit matrix's config.php and add
  # 'overwritehost' => 'matrix.mbund.org',

  virtualisation.oci-containers.containers.matrixconduit = {
    image = "matrixconduit/matrix-conduit";
    environment = {
      CONDUIT_SERVER_NAME = "mbund.org";
      CONDUIT_DATABASE_PATH = "/var/lib/matrix-conduit";
      CONDUIT_PORT = "6167";
      CONDUIT_DATABASE_BACKEND = "rocksdb";
      CONDUIT_ALLOW_REGISTRATION = "true";
      CONDUIT_ALLOW_FEDERATION = "true";
      CONDUIT_MAX_REQUEST_SIZE = "20000000";
      CONDUIT_TRUSTED_SERVERS = "[\"matrix.org\"]";
      CONDUIT_MAX_CONCURRENT_REQUESTS = "100";
      CONDUIT_LOG = "info";
      CONDUIT_ADDRESS = "0.0.0.0";
    };
    volumes = [
      "${data}/matrixconduit-container/db:/var/lib/matrix-conduit"
    ];
    ports = [
      "127.0.0.1:${builtins.toString port}:6167"
    ];
    extraOptions = [ "--network=matrix-br" ];
    user = "${builtins.toString uid}:${builtins.toString uid}";
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
    "v ${data}/matrixconduit-container    770 ${user} ${user} - -"
    "v ${data}/matrixconduit-container/db 770 ${user} ${user} - -"
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
