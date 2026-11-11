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
6. Activates home-manager (`homeConfigurations.james`). This installs rex
   and runs `rex server` as a systemd user service on the tailnet.
   Files it would replace are kept as `*.hm-bak`.
7. Enables systemd linger, so the rex server keeps running after logout.

Idempotent — re-run safely after edits.

After first install, npm-based tools that aren't in nixpkgs:

```sh
npm install -g jj-stack @openai/codex
```

## Rex

`home.nix` runs the rex server as the `rex` systemd user service, with
Tailscale on, `tag:work` advertised and tailnet members allowed. The tailnet
hostname is `rex-%l`: systemd expands `%l` to the short hostname, so each box
gets its own node (for example `rex-devbox-james`).

On a new box, approve the node once. The login URL is in the log:

```sh
just rex-status     # or: journalctl --user -u rex
```

## Day-to-day

```sh
just            # show available recipes
just upgrade    # bump pins (flake.lock) and rebuild
just apply      # rebuild the profile and switch home-manager, no bump
just rex-status # rex service status and log
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
├── flake.nix          # nix profile source + home-manager config
├── flake.lock
├── home.nix           # home-manager: rex service, ssh config
└── home/              # mirror of $HOME, symlinked in by install.sh
    ├── .gitconfig
    ├── .gitignore_global
    ├── .zshrc
    ├── .zsh_aliases
    ├── .ssh/rc        # keeps ~/.ssh/agent.sock pointed at the newest agent
    └── .config/
        ├── atuin/config.toml
        ├── git/ignore
        ├── jj/config.toml
        ├── starship.toml
        └── zellij/config.kdl
```

home-manager writes `~/.ssh/config`, so do not put it under `home/`.

## What's in the flake

- nixpkgs: `atuin`, `cargo-binstall`, `delta`, `gh`, `go`, `jujutsu` (jj), `nodejs`,
  `starship`, `zellij`.
- **`jj-domino`** — pulled from upstream flake
  (`github:zombiezen/jj-domino`), not nixpkgs.
- **`home-manager`** and **`rex`** (preview channel, unfree, prebuilt from
  `pkgs.superlogical.com`) — used by `homeConfigurations.james`.

## Why this exists

Migrated off chezmoi + mise. Pattern based on
<https://github.com/jeremywmoore/dotfiles>; context for the nix switch:
<https://gist.github.com/jeremywmoore/6c5a3349d1fa79ab474343c9f0feeab9>.
