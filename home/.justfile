# Recipes that run from $HOME, for example `ssh -t <devbox> just onboard`.

# Set up a new box
onboard: setup-atuin

# Log in to atuin sync and pull history
setup-atuin:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -s "${XDG_DATA_HOME:-$HOME/.local/share}/atuin/session" ]; then
      echo "atuin is already logged in."
    else
      if [ ! -t 0 ]; then
        echo "atuin login prompts for a password and key. Run: ssh -t <devbox> just onboard" >&2
        exit 1
      fi
      echo "Log in to atuin. Get the key on a machine that is logged in: atuin key"
      atuin login
    fi
    atuin sync
