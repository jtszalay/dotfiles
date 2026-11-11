# zsh reads only zshenv for a command over ssh (`ssh box just ...`), so the nix profile goes on PATH here.
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
