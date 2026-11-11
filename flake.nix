{
  description = "james personal toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    jj-domino.url = "github:zombiezen/jj-domino";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Rex is prebuilt and unfree. flake.lock pins the exact release; `just bump-input rex` moves it.
    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, jj-domino, home-manager, rex }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.buildEnv {
          name = "personal-tools";
          paths = with pkgs; [
            atuin
            cargo-binstall
            delta            # syntax-highlighting pager for diffs (jj uses it)
            gh
            go
            jujutsu          # jj
            just
            nodejs           # `npm i -g jj-stack @openai/codex` after install
            starship
            zellij
            jj-domino.packages.${system}.default
          ];
        };
      })
    // {
      # home-manager owns what needs more than a binary on PATH: the rex user service,
      # its terminfo entry, and its ssh guard. Plain CLI tools stay in packages.default.
      homeConfigurations.james = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          rex.homeManagerModules.default
          ./home.nix
        ];
      };
    };
}
