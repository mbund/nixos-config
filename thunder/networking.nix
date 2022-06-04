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
        # Every required port is opened here, including some internal ones. A separate,
        # dedicated firewall should allow only the absolutely required ports. The
        # required ports are, by arbitrary convention here, the first column of numbers.
        22
        443  4430
      ];
    };
    extraCommands = ''
      # Redirect all incoming https (443) traffic through to port 4430
      ip46tables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 4430

      # Redirect *all exclusively local (OUTPUT not POSTROUTING)* packets that are going out from port 4430 to port 443
      ip46tables -t nat -A OUTPUT -p tcp --dport 4430 -j DNAT --to-destination :443
    '';
  };
  
  # proxies
  environment.etc."caddy".source = ./caddy;
}
