# Recipes that run from $HOME, for example `ssh -t <devbox> just onboard`.

# Set up a new box: log in to atuin, then add the rex server to the tailnet
onboard: setup-atuin setup-rex-tailscale

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
      atuin login -u ngrokjames
    fi
    atuin sync

# Print the Tailscale sign-in link for the rex server, or its tailnet URL when it is already enrolled
setup-rex-tailscale:
    #!/usr/bin/env bash
    set -euo pipefail
    id="$(systemctl --user show -p InvocationID --value rex)"
    if [ -z "$id" ]; then
      echo "The rex service is not running. Check: systemctl --user status rex" >&2
      exit 1
    fi
    # Follow the current server's log until it shows a sign-in link or a ready listener.
    line="$(timeout 60 journalctl --user -n all -f -o cat _SYSTEMD_INVOCATION_ID="$id" \
      | grep -m1 -oE 'https://login\.tailscale\.com/[^ ]+|listener ready.*url=[^ ]+' || true)"
    case "$line" in
      https://*) echo "Open this link to add the rex server to the tailnet: $line" ;;
      *url=*) echo "The rex server is already on the tailnet: ${line##*url=}" ;;
      *) echo "No sign-in link after 60s. Check: journalctl --user -u rex" >&2; exit 1 ;;
    esac
