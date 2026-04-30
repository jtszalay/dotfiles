# dotfiles

Personal toolchain (a nix flake) + config (symlinked from `home/`), set up
via `install.sh`.

## Install

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh`:

1. Symlinks every file under `home/` into the matching path in `$HOME`
   (relative symlinks, so the repo can be relocated).
2. Sets the default login shell to `zsh` if it isn't already.
3. Installs Determinate Nix if `nix` isn't on PATH.
4. Starts `nix-daemon` if it's not running (containers without systemd).
5. Installs the nix profile entry from this flake.

Idempotent — re-run safely after edits.

After first install, npm-based tools that aren't in nixpkgs:

```sh
npm install -g jj-stack @openai/codex
```

## Day-to-day

```sh
just            # show available recipes
just upgrade    # bump pins (flake.lock) and rebuild
just packages   # list every tool with its resolved version
just rollback   # revert to previous nix profile generation
just edit       # open flake.nix in $EDITOR
```

Edit `home/<...>` files in place — they're symlinked, so `$HOME` edits
are repo edits. The starship prompt shows a yellow `●` when there are
uncommitted changes here.

## Layout

```
.
├── README.md
├── install.sh
├── justfile
├── flake.nix          # nix profile source
├── flake.lock
└── home/              # mirror of $HOME, symlinked in by install.sh
    ├── .zshrc
    ├── .zsh_aliases
    └── .config/
        ├── jj/config.toml
        └── starship.toml
```

## What's in the flake

- nixpkgs: `cargo-binstall`, `delta`, `gh`, `go`, `jujutsu` (jj), `nodejs`,
  `starship`, `zellij`.
- **`jj-domino`** — pulled from upstream flake
  (`github:zombiezen/jj-domino`), not nixpkgs.

## Why this exists

Migrated off chezmoi + mise. Pattern based on
<https://github.com/jeremywmoore/dotfiles>; context for the nix switch:
<https://gist.github.com/jeremywmoore/6c5a3349d1fa79ab474343c9f0feeab9>.
