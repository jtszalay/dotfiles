#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# 1. Symlink home/* into $HOME — works even without nix; never blocks the rest.
# sshd ignores ~/.ssh/rc and authorized_keys when ~/.ssh is group- or world-writable.
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
find home -type f | while read -r src; do
  dest="$HOME/${src#home/}"
  mkdir -p "$(dirname "$dest")"
  ln -srfv "$PWD/$src" "$dest"
done

# 2. Set default shell to zsh if it isn't already.
zsh_path="$(command -v zsh 2>/dev/null || true)"
if [ -z "$zsh_path" ]; then
  echo "warning: zsh not found in PATH; default shell unchanged" >&2
elif [ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]; then
  if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
    echo "$zsh_path missing from /etc/shells; adding (sudo)…"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  # `chsh` (without sudo) authenticates the user via PAM and prompts for a
  # password — which is awkward on devboxes / Codespaces where the user has
  # passwordless sudo but no actual password. Run chsh as root targeting
  # the user explicitly to skip the PAM auth.
  if sudo chsh -s "$zsh_path" "$USER"; then
    echo "Default shell set to $zsh_path. Open a new login session to use it."
  else
    echo "warning: chsh failed; default shell unchanged" >&2
  fi
fi

# 3. Load nix if it is installed. Devboxes come with nix, but devbox provisioning
# runs this script in a non-login shell (sudo -u <user> bash -c), which does not
# source the nix profile.
nix_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
# shellcheck source=/dev/null
[ -f "$nix_profile" ] && . "$nix_profile"

# Install Determinate Nix if it is still missing. --no-confirm is for
# non-interactive boots such as Codespaces.
if ! command -v nix >/dev/null 2>&1; then
  echo "nix not found — installing Determinate Nix…"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --determinate --no-confirm
  # shellcheck source=/dev/null
  [ -f "$nix_profile" ] && . "$nix_profile"
fi

# 4. Start nix-daemon if it isn't running. Containers without systemd
# (Codespaces, plain Docker) don't auto-start it, so `nix profile add`
# fails with "cannot connect to socket".
if command -v nix >/dev/null 2>&1 && ! nix store ping >/dev/null 2>&1; then
  # Resolve the full path: nix-daemon usually isn't on root's PATH (it
  # lives under /nix/var/nix/profiles/default/bin), and sudo searches its
  # own PATH unless given an absolute path.
  nix_daemon_path="$(command -v nix-daemon 2>/dev/null || true)"
  if [ -n "$nix_daemon_path" ]; then
    echo "Starting nix-daemon in background (no systemd — common in containers)…"
    nix_daemon_log=/tmp/nix-daemon.log
    sudo -b sh -c "$nix_daemon_path >$nix_daemon_log 2>&1"
    # Poll up to 10s for the socket to appear.
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      [ -S /nix/var/nix/daemon-socket/socket ] && break
      sleep 1
    done
    if ! nix store ping >/dev/null 2>&1; then
      echo "  warning: nix-daemon didn't come up. Last 20 lines of $nix_daemon_log:" >&2
      tail -20 "$nix_daemon_log" >&2 || true
    fi
  fi
fi

# 5. (Re)install nix profile from the flake. Best-effort — print recovery
# guidance instead of aborting if the daemon still isn't reachable.
if command -v nix >/dev/null 2>&1; then
  nix profile remove dotfiles 2>/dev/null || true
  nix profile remove flake 2>/dev/null || true
  if ! nix profile add "$PWD"; then
    echo "warning: 'nix profile add' failed." >&2
    echo "  If it's a daemon issue: sudo nix-daemon & ; nix profile add $PWD" >&2
  fi
else
  echo "warning: nix not on PATH after install; open a fresh shell and re-run ./install.sh" >&2
fi

# 6. Activate home-manager from the pinned flake input. This installs rex and its
# systemd user service. Files home-manager would overwrite are kept as *.hm-bak.
if command -v nix >/dev/null 2>&1; then
  if hm_gen="$(nix build --no-link --print-out-paths "$PWD#homeConfigurations.james.activationPackage")"; then
    HOME_MANAGER_BACKUP_EXT=hm-bak "$hm_gen/activate" \
      || echo "warning: home-manager activation failed" >&2
  else
    echo "warning: home-manager build failed" >&2
  fi
fi

# 7. Keep user services (the rex server) running while logged out.
if command -v loginctl >/dev/null 2>&1 \
  && [ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" != yes ]; then
  sudo loginctl enable-linger "$USER" || echo "warning: enable-linger failed" >&2
fi
