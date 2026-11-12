{ lib, ... }:
{
  home.username = "james";
  home.homeDirectory = "/home/james";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # programs.rex adds its ssh guard to ~/.ssh/config, which home-manager writes only with this on.
  programs.ssh = {
    enable = true;
    # Keep ssh's stock defaults instead of the Host * block home-manager would add.
    enableDefaultConfig = false;
  };

  programs.rex.enable = true;

  # The server listens only on its unix socket. Clients reach it through an ssh forward.
  services.rex.enable = true;

  # leaf's Rex palette plugin. leaf rewrites its block of init.lua at runtime, so
  # home-manager can't own the file; install the block once and leaf keeps it
  # current after that. Point it at the profile's leaf, not the store path
  # `leaf rex install` records, so it survives upgrades and gc.
  home.activation.leafRexPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    leaf="$HOME/.nix-profile/bin/leaf"
    config="$HOME/.config/rex/init.lua"
    if [ -x "$leaf" ] && ! grep -qs '^-- >>> leaf >>>' "$config"; then
      export PATH="$HOME/.nix-profile/bin:$PATH"
      if run "$leaf" rex install; then
        run sed -i "s|bin = { \"/nix/store/[^\"]*\" }|bin = { \"$leaf\" }|" "$config"
        run rex config reload || true
      else
        warnEcho "leaf rex install failed; run it by hand"
      fi
    fi
  '';
}
