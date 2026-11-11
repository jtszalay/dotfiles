# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.

unsetopt autocd

export PATH=$HOME/.bun/bin:$HOME/bin:$HOME/.local/bin:$PATH

# Strip stale mise install paths injected by parent processes — most
# commonly VS Code Remote's resolved shell env, captured at server
# startup and replayed into every terminal. Tools migrated to nix; the
# VS Code Server is long-lived and may still hand out PATHs from when
# mise was active.
PATH=$(printf '%s' "$PATH" | tr ':' '\n' | grep -vE '/\.local/share/mise/installs/' | paste -sd:)

# atuin (enhanced shell history)
if [[ -f "$HOME/.atuin/bin/env" ]]; then
  . "$HOME/.atuin/bin/env"
  eval "$(atuin init zsh)"
fi

eval "$(starship init zsh)"

source <(jj util completion zsh)

source ~/.zsh_aliases

#eval "$(zellij setup --generate-auto-start zsh)"

# Follow the newest SSH connection's forwarded agent (symlink maintained by
# ~/.ssh/rc) so long-lived shells survive VS Code reconnects.
if [ -L "$HOME/.ssh/agent.sock" ]; then
	export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
fi

# mise marker: begin frontend/scripts/setup
if [ -z "${MISE_SHELL:-}" ]; then
  if [ -x "$HOME/.local/bin/mise" ]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
  fi
fi
# mise marker: end frontend/scripts/setup
