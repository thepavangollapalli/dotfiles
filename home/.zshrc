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
# Set here, not in .zshenv: macOS /etc/zshrc overwrites HISTFILE with
# ~/.zsh_history before ~/.zshrc runs.
HISTFILE="$HOME/.zhistory"
HISTSIZE=50000
SAVEHIST=50000

# oh-my-zsh ------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"

# This file is symlinked from <repo>/home/.zshrc. Resolve that symlink back to
# the repo root so custom OMZ themes/plugins are stored in the repo itself.
DOTFILES_DIR="${${(%):-%x}:A:h:h}"
export ZSH_CUSTOM="$DOTFILES_DIR/zsh/custom"

# Keep the dump per zsh version: /bin/zsh and Homebrew zsh differ, and a .zwc
# compiled by one is rejected by the other ("wrong version" on startup).
export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${ZSH_COMPDUMP:h}"

ZSH_THEME="agnoster"
DEFAULT_USER="$USER"
plugins=(git brew macos extract sudo colored-man-pages z)
source "$ZSH/oh-my-zsh.sh"

# History --------------------------------------------------------------------
setopt hist_ignore_space hist_ignore_all_dups hist_reduce_blanks
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
