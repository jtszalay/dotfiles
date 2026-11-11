{ ... }:
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
}
