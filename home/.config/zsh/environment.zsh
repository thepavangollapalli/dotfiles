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

# Shared Freshpaint development defaults. Credentials stay on each computer.
export ENV=dev
export PERFALYTICS_DB_CONN_STRING="host=localhost port=7432 user=postgres dbname=postgres sslmode=disable"
export SUMMARY_DB_CONN_STRING="host=localhost port=7433 user=postgres dbname=postgres sslmode=disable"
export PERSONAS_DB_CONN_STRING="host=localhost port=7434 user=postgres dbname=postgres sslmode=disable"
export DATA_ACTIVATION_DB_CONN_STRING="host=localhost port=7435 user=postgres dbname=postgres sslmode=disable"
export MOCK_S3_HOST="http://127.0.0.1:9090"
export GOTEST=gotest
export GOPRIVATE=github.com/freshpaint-io

# This file is private, optional, and never managed by install.sh.
if [[ -r "$HOME/.config/zsh/credentials.zsh" ]]; then
  source "$HOME/.config/zsh/credentials.zsh"
fi
