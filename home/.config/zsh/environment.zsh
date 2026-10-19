# Homebrew may not yet be on PATH in a new login shell.
if [[ -z ${HOMEBREW_PREFIX:-} ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv zsh)"
  fi
fi

export BUN_INSTALL="$HOME/.bun"
typeset -U path
path=("$HOME/.local/bin" "$BUN_INSTALL/bin" "$HOME/.opencode/bin" $path "$HOME/.docker/bin")
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  path=("$HOMEBREW_PREFIX/opt/postgresql@18/bin" "$HOMEBREW_PREFIX/opt/ruby/bin" $path)
fi
if (( $+commands[go] )); then
  path+=("$(go env GOPATH)/bin")
fi
export PATH

# This file is private, optional, and never managed by install.sh.
if [[ -r "$HOME/.config/zsh/credentials.zsh" ]]; then
  source "$HOME/.config/zsh/credentials.zsh"
fi
