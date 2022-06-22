{ config, pkgs, ... }:
{
  services.yggdrasil = {
    enable = true;
    persistentKeys = true;
    openMulticastPort = true;
    config = {
      IfName = "yggdrasil0";
      Peers = [
        # https://publicpeers.neilalexander.dev/
        "tcp://ygg-ny-us.incognet.io:8883"
        "tls://ygg-ny-us.incognet.io:8884"
        "tcp://tasty.chowder.land:9002"
      ];
    };
  };
  
  time.timeZone = "America/New_York";
}
