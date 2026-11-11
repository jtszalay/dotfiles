_dotfiles := justfile_directory()

# Show available recipes
default:
    @just --list

# Bump input pins (flake.lock) and apply
upgrade: bump apply

# Bump input pins only (no rebuild yet)
bump:
    nix flake update --flake {{ _dotfiles }}

# Apply current flake.nix selection without bumping pins
apply:
    nix profile upgrade dotfiles
    HOME_MANAGER_BACKUP_EXT=hm-bak "$(nix build --no-link --print-out-paths {{ _dotfiles }}#homeConfigurations.james.activationPackage)/activate"

# Show the rex server's status and recent log
rex-status:
    systemctl --user status rex --no-pager || true
    journalctl --user -u rex -n 30 --no-pager

# Bump only one input (e.g. `just bump-input nixpkgs`)
bump-input input:
    nix flake update --flake {{ _dotfiles }} {{ input }}

# Show installed profile entries (the flake itself)
list:
    nix profile list

# Show every tool in the buildEnv with its resolved name-version
packages:
    @for b in ~/.nix-profile/bin/*; do realpath "$b"; done \
        | sed 's|/bin/.*||' \
        | sort -u \
        | sed 's|^/nix/store/[a-z0-9]\{32\}-||'

# Show what changed between current and previous generation
diff:
    nix profile diff-closures

# Roll back to the previous generation
rollback:
    nix profile rollback

# Verify the flake evaluates cleanly
check:
    nix flake check {{ _dotfiles }}

# Open flake.nix in $EDITOR
edit:
    ${EDITOR:-vi} {{ _dotfiles }}/flake.nix

# Drop old profile generations and unreferenced store paths
gc:
    nix profile wipe-history
    nix-collect-garbage
