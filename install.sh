#!/usr/bin/env bash
# Symlink every file under home/ into $HOME.
# Existing files are backed up to ~/.dotfiles-backup/<timestamp>/ first.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run]

Symlinks everything under home/ into your home directory.
Files that already exist are moved to ~/.dotfiles-backup/<timestamp>/.
EOF
}

case "${1:-}" in
  "") ;;
  --dry-run) DRY_RUN=1 ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if [[ ! -d "$SRC_DIR" ]]; then
  echo "error: missing $SRC_DIR" >&2
  exit 1
fi

# oh-my-zsh is an external framework; only the configuration lives in this repo.
OMZ_DIR="$HOME/.oh-my-zsh"
if [[ ! -f "$OMZ_DIR/oh-my-zsh.sh" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "would clone oh-my-zsh into $OMZ_DIR"
  else
    echo "cloning oh-my-zsh into $OMZ_DIR"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
  fi
fi

linked=0
while IFS= read -r src; do
  rel="${src#"$SRC_DIR"/}"
  dest="$HOME/$rel"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "would link ~/$rel -> $src"
    linked=$((linked + 1))
    continue
  fi

  mkdir -p -- "$(dirname -- "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p -- "$BACKUP_DIR/$(dirname -- "$rel")"
    mv -- "$dest" "$BACKUP_DIR/$rel"
    echo "backed up ~/$rel"
  fi

  ln -sfn -- "$src" "$dest"
  echo "linked ~/$rel"
  linked=$((linked + 1))
done < <(find "$SRC_DIR" -type f ! -name '.DS_Store' | sort)

if [[ $DRY_RUN -eq 0 ]]; then
  echo
  echo "$linked link(s) installed."
  if [[ -d "$BACKUP_DIR" ]]; then
    echo "Previous files: $BACKUP_DIR"
  fi
fi
