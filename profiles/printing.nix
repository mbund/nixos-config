{ pkgs, ... }: {
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      gutenprintBin
      foo2zjs
      # hplipWithPlugin
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
  };
}
