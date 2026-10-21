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

clone_dependency() {
  local url="$1" destination="$2" installed_file="$3"
  if [[ -f "$destination/$installed_file" ]]; then
    return
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "would clone $url into $destination"
  else
    echo "cloning $url into $destination"
    git clone --depth=1 "$url" "$destination"
  fi
}

download_dependency() {
  local url="$1" destination="$2" temporary_file
  if [[ -f "$destination" ]]; then
    return
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "would download $url into $destination"
  else
    echo "downloading $url into $destination"
    mkdir -p -- "$(dirname -- "$destination")"
    temporary_file="$(mktemp "$destination.XXXXXX")"
    if curl --fail --location --silent --show-error --output "$temporary_file" "$url"; then
      mv -- "$temporary_file" "$destination"
    else
      rm -f -- "$temporary_file"
      return 1
    fi
  fi
}

# Download dependencies to their standard locations; keep them out of git.
OMZ_DIR="$HOME/.oh-my-zsh"
clone_dependency https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR" oh-my-zsh.sh
download_dependency \
  https://raw.githubusercontent.com/ChesterYue/ohmyzsh-theme-passion/main/passion.zsh-theme \
  "$OMZ_DIR/custom/themes/passion.zsh-theme"
clone_dependency https://github.com/zsh-users/zsh-autosuggestions.git \
  "$OMZ_DIR/custom/plugins/zsh-autosuggestions" zsh-autosuggestions.plugin.zsh
clone_dependency https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$OMZ_DIR/custom/plugins/zsh-syntax-highlighting" zsh-syntax-highlighting.plugin.zsh
clone_dependency https://github.com/nvm-sh/nvm.git "$HOME/.nvm" nvm.sh
clone_dependency https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm" tpm
clone_dependency https://github.com/tmux-plugins/tmux-resurrect.git \
  "$HOME/.tmux/plugins/tmux-resurrect" resurrect.tmux

linked=0
while IFS= read -r source_file; do
  relative_path="${source_file#"$SRC_DIR"/}"
  destination="$HOME/$relative_path"

  if [[ -L "$destination" && "$(readlink "$destination")" == "$source_file" ]]; then
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "would link ~/$relative_path -> $source_file"
    linked=$((linked + 1))
    continue
  fi

  mkdir -p -- "$(dirname -- "$destination")"

  if [[ -e "$destination" || -L "$destination" ]]; then
    mkdir -p -- "$BACKUP_DIR/$(dirname -- "$relative_path")"
    mv -- "$destination" "$BACKUP_DIR/$relative_path"
    echo "backed up ~/$relative_path"
  fi

  ln -sfn -- "$source_file" "$destination"
  echo "linked ~/$relative_path"
  linked=$((linked + 1))
done < <(find "$SRC_DIR" -type f ! -name '.DS_Store' ! -name 'credentials.zsh' | sort)

if [[ $DRY_RUN -eq 0 ]]; then
  echo
  echo "$linked link(s) installed."
  if [[ -d "$BACKUP_DIR" ]]; then
    echo "Previous files: $BACKUP_DIR"
  fi
  echo
  echo 'To load the zsh config and passion theme, open a new zsh session or run:'
  echo '  exec zsh -l'
fi
