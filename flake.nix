{
  description = "james personal toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    jj-domino.url = "github:zombiezen/jj-domino";
    # leaf: terminal reader + diff reviewer with a Rex plugin (`leaf rex install`).
    leaf = {
      url = "github:DeepanshuMishraa/leaf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

  outputs = { self, nixpkgs, flake-utils, jj-domino, leaf, home-manager, rex }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # claude-code is unfree; allow it by name rather than everything.
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
        };
      in {
        packages.default = pkgs.buildEnv {
          name = "personal-tools";
          paths = with pkgs; [
            atuin
            cargo-binstall
            claude-code
            delta            # syntax-highlighting pager for diffs (jj uses it)
            gh
            go
            gum              # screenr picker
            screen
            jujutsu          # jj
            just
            nodejs           # `npm i -g jj-stack @openai/codex` after install
            starship
            zellij
            jj-domino.packages.${system}.default
            # Upstream package.nix leaves out sqlite and (on Linux) alsa-lib, which leaf links against.
            (leaf.packages.${system}.default.overrideAttrs (old: {
              buildInputs = old.buildInputs ++ [ pkgs.sqlite ] ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.alsa-lib;
            }))
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
