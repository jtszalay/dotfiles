{
  description = "james personal toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    jj-domino.url = "github:zombiezen/jj-domino";
  };

  outputs = { self, nixpkgs, flake-utils, jj-domino }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.buildEnv {
          name = "personal-tools";
          paths = with pkgs; [
            cargo-binstall
            delta            # syntax-highlighting pager for diffs (jj uses it)
            gh
            go
            jujutsu          # jj
            nodejs           # `npm i -g jj-stack @openai/codex` after install
            starship
            zellij
            jj-domino.packages.${system}.default
          ];
        };
      });
}
