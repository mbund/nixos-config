{ pkgs, config, lib, ... }:
{

  imports = [
    ./gitlab.nix
  ];
  
  networking = {
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    # usePredictableInterfaceNames = false;
    networkmanager.enable = true;
    hostName = "thunder";
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    ports = [ 22 ];
    openFirewall = false;
    passwordAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat    
  ];

  # Linode longview system stats
  services.longview = {
    enable = true;
    apiKeyFile = "/var/lib/longview-secrets/longview.key";
  };

  # DNS-over-TLS
  services.stubby = {
    enable = true;
    settings = {
      resolution_type = "GETDNS_RESOLUTION_STUB";
      dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
      tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
      tls_query_padding_blocksize = 256;
      edns_client_subnet_private = 1; # true
      idle_timeout = 10000;
      listen_addresses = [ "127.0.0.1" "0::1" ];
      round_robin_upstreams = 0; # false
      upstream_recursive_servers = [
        {
          address_data = "2606:4700:4700::1111";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "2606:4700:4700::1001";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "1.1.1.1";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "1.0.0.1";
          tls_auth_name = "cloudflare-dns.com";
        }

        # {
        #   address_data = "185.49.141.38";
        #   tls_auth_name = "getdnsapi.net";
        #   tls_pubkey_pinset = [{
        #     digest = "sha256";
        #     value = "foxZRnIh9gZpWnl+zEiKa0EJ2rdCGroMWm02gaxSc9Q=";
        #   }];
        # }
      ];
    };
  };

  # point systemd dns to stubby, and allow unencrypted DNS fallbacks
  networking.nameservers = [ "::1" "127.0.0.1" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "2606:4700:4700::1111" "2606:4700:4700::1001" "1.1.1.1" "1.0.0.1" ];
  };

  # port forwarding
  networking.firewall = {
    enable = true;
    interfaces.eth0 = {
      allowedTCPPorts = [
        22
        443
      ];
    };
    extraCommands = ''
      ip6tables -t nat -I PREROUTING -i ens3 -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 4430
    '';
  };
  
  # proxies
  environment.etc."caddy".source = ./caddy;
}
