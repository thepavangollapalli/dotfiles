# ============================================================================
# ~/.zshrc — managed by ~/code/dotfiles
# ============================================================================

# Homebrew & tool paths ------------------------------------------------------
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.local/bin:$BUN_INSTALL/bin:$HOME/.opencode/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:/opt/homebrew/opt/ruby/bin:$PATH"

export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER=less
export LESS='-FRX'
export CLICOLOR=1

# History --------------------------------------------------------------------
HISTFILE="$HOME/.zhistory"
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_space hist_ignore_all_dups hist_reduce_blanks
setopt inc_append_history share_history
setopt autocd extendedglob interactive_comments no_flow_control

# Completion -----------------------------------------------------------------
mkdir -p "$HOME/.cache/zsh"
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%F{blue}%d%f'

# Key bindings ---------------------------------------------------------------
bindkey -v
export KEYTIMEOUT=1
bindkey '^R' history-incremental-search-backward
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

# Prompt ---------------------------------------------------------------------
autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:git:*' formats ' %F{green}%b%f'
zstyle ':vcs_info:git:*' actionformats ' %F{green}%b%f%F{red}|%a%f'
add-zsh-hook precmd vcs_info
setopt promptsubst
PROMPT='%F{blue}%~%f${vcs_info_msg_0_} %# '
RPROMPT='%(?..%F{red}%?%f)'

# Aliases --------------------------------------------------------------------
alias ll='ls -alF'
alias la='ls -A'
alias e='vim'
alias v='vim'
alias path='print -l $path'
alias reload='exec zsh -l'

# Functions ------------------------------------------------------------------
g() {
  if (( $# )); then
    git "$@"
  else
    git status
  fi
}

mcd() {
  if (( $# != 1 )); then
    print -u2 'usage: mcd <dir>'
    return 1
  fi
  mkdir -p -- "$1" && cd -- "$1"
}

envup() {
  if [[ ! -f .env ]]; then
    print -u2 'No .env file found'
    return 1
  fi
  set -a
  source .env
  set +a
}
