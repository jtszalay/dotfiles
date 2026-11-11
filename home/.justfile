# Recipes that run from $HOME, for example `ssh <devbox> just setup-rex-tailscale`.

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
