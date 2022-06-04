{ pkgs, lib, config, ... }:
let
  host = "searx.mbund.org";
  port = 4431;
  name = "searxng";
  user = "thunder-searxng";
  data = "/home/${user}";
in {
  virtualisation.oci-containers.containers.${name} = {
    image = "searxng/searxng";
    environment = {
      BASE_URL = "https://${host}";
      INSTANCE_NAME = "mearxng";
    };
    volumes = [
      "${data}/${name}-container:/etc/searxng"
    ];
    ports = [
      "127.0.0.1:${builtins.toString port}:8080"
    ];
  };

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
