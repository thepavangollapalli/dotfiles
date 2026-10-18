# dotfiles

Personal macOS dotfiles. Plain config files live under `home/` and are
symlinked into `$HOME` by a small installer. The shell is built on
[oh-my-zsh](https://ohmyz.sh/); OMZ itself is cloned by the installer and is
not vendored here, but all of its configuration and any custom themes/plugins
are stored in this repo.

## Layout

```
dotfiles/
├── home/              # mirrors $HOME; everything here gets symlinked
│   ├── .zshrc         # oh-my-zsh + personal settings
│   ├── .tmux.conf
│   ├── .vimrc
│   ├── .gitconfig
│   └── .gitignore     # global git ignore
├── zsh/custom/        # ZSH_CUSTOM: OMZ themes/plugins, versioned here
├── install.sh         # clones OMZ, creates symlinks, backs up replacements
├── Brewfile           # core CLI tools
└── README.md
```

## Install

```sh
git clone git@github.com:thepavangollapalli/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./install.sh --dry-run   # preview
./install.sh
exec zsh -l
```

`install.sh` moves any existing file it would replace into
`~/.dotfiles-backup/<timestamp>/`, then symlinks the repo copy. Re-running it
is safe and idempotent.

## What's managed

| File | Purpose |
| --- | --- |
| `~/.zshrc` | oh-my-zsh (`agnoster`, plugins), Homebrew paths, 50k history, vi mode |
| `~/.tmux.conf` | `C-a` prefix, vi copy mode, `\|`/`-` splits, 50k scrollback, mouse |
| `~/.vimrc` | vim-plug bootstrap, fugitive/surround/repeat/fzf.vim/seoul256, 2-space tabs |
| `~/.gitconfig` | identity, rebase-on-pull, useful aliases, osxkeychain |
| `~/.gitignore` | global ignores (`.DS_Store`, swap files) |

Command history (`~/.zhistory`), SSH keys, and app configs under `~/.config`
are intentionally **not** managed here.

## After installing

- **vim**: the first launch downloads vim-plug and installs the plugins
  automatically. If it doesn't, run `:PlugInstall`.
- **tmux**: reload with `prefix r` (`C-a r`) or restart the server.
- **zsh**: `exec zsh -l`, or just open a new terminal. The prompt is the OMZ
  `agnoster` theme, which needs a Powerline/Nerd Font in your terminal. Meslo
  LG L for Powerline is already installed; select it in your terminal if any
  prompt glyphs render as boxes.
- **oh-my-zsh**: installed to `~/.oh-my-zsh` by `install.sh`. Personalized
  pieces:
  - `ZSH_THEME` and `plugins=(...)` live in `home/.zshrc`
  - custom themes/plugins live in `zsh/custom/` (`ZSH_CUSTOM` points there)

## Adding a file

Put it under `home/` using the same relative path it has in `$HOME`, then run
`./install.sh`.

```sh
cp ~/.config/foo/bar.conf home/.config/foo/bar.conf
./install.sh
```

## Notes

- `install.sh` only symlinks regular files; it does not copy. It clones
  oh-my-zsh if `~/.oh-my-zsh` is missing (requires `git` and network access).
- The repo's history includes the previous `dotfiles-local` setup. The 2026-10
  rebuild dropped the thoughtbot layer, RVM/asdf leftovers, NERDTree-era vim
  bundles, and the battery/Spotify tmux scripts.
- Remote: `git@github.com:thepavangollapalli/dotfiles.git`
