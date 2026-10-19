# ============================================================================
# ~/.zshrc — managed by ~/code/dotfiles
# ============================================================================

# Also load the environment for interactive shells started without login.
source "$HOME/.config/zsh/environment.zsh"

export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER=less
export LESS='-FRX'
export CLICOLOR=1

# History --------------------------------------------------------------------
# Set here, not in .zshenv: macOS /etc/zshrc overwrites HISTFILE with
# ~/.zsh_history before ~/.zshrc runs.
HISTFILE="$HOME/.zhistory"
HISTSIZE=50000
SAVEHIST=50000

# oh-my-zsh ------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

# Keep the dump per zsh version: /bin/zsh and Homebrew zsh differ, and a .zwc
# compiled by one is rejected by the other ("wrong version" on startup).
export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${ZSH_COMPDUMP:h}"

ZSH_THEME="agnoster"
DEFAULT_USER="$USER"
plugins=(
  git
  brew
  macos
  extract
  sudo
  colored-man-pages
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"

# Node versions --------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
  autoload -Uz add-zsh-hook

  load-nvmrc() {
    local nvmrc_path requested_version
    nvmrc_path="$(nvm_find_nvmrc)"

    if [[ -n "$nvmrc_path" ]]; then
      requested_version="$(nvm version "$(< "$nvmrc_path")")"
      if [[ "$requested_version" == N/A ]]; then
        nvm install
      elif [[ "$requested_version" != "$(nvm version)" ]]; then
        nvm use
      fi
    elif [[ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ]] &&
         [[ "$(nvm version)" != "$(nvm version default)" ]]; then
      nvm use default
    fi
  }

  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

# Cortex maintains its own completion file.
if [[ -s "$HOME/.zsh/completions/cortex.zsh" ]]; then
  source "$HOME/.zsh/completions/cortex.zsh"
fi

# History options ------------------------------------------------------------
setopt hist_ignore_space hist_ignore_all_dups hist_find_no_dups hist_reduce_blanks
setopt inc_append_history share_history
setopt autocd extendedglob interactive_comments no_flow_control

# Completion styling ---------------------------------------------------------
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

# Aliases --------------------------------------------------------------------
alias ll='ls -alF'
alias la='ls -A'
alias e='vim'
alias v='vim'
alias path='print -l $path'
alias reload='exec zsh -l'
alias hg='history | grep'

# Functions ------------------------------------------------------------------
unalias g 2>/dev/null

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
