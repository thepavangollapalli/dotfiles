# dotfiles

Personal macOS dotfiles. Plain config files live under `home/` and are
symlinked into `$HOME` by a small installer — no framework, no extra
dependencies.

## Layout

```
dotfiles/
├── home/              # mirrors $HOME; everything here gets symlinked
│   ├── .zshrc
│   ├── .tmux.conf
│   ├── .vimrc
│   ├── .gitconfig
│   └── .gitignore     # global git ignore
├── install.sh         # creates the symlinks, backs up anything it replaces
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
| `~/.zshrc` | Homebrew paths, 50k history, completion, vi mode, git-aware prompt |
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
- **zsh**: `exec zsh -l`, or just open a new terminal.
- Optional syntax highlighting/autosuggestions are not wired up. If you want
  them: `brew install zsh-syntax-highlighting zsh-autosuggestions`, then add
  the `source` lines at the very bottom of `~/.zshrc`.

## Adding a file

Put it under `home/` using the same relative path it has in `$HOME`, then run
`./install.sh`.

```sh
cp ~/.config/foo/bar.conf home/.config/foo/bar.conf
./install.sh
```

## Notes

- `install.sh` only symlinks regular files; it does not copy.
- The repo's history includes the previous `dotfiles-local` setup. The 2026-10
  rebuild dropped the thoughtbot layer, RVM/asdf leftovers, NERDTree-era vim
  bundles, and the battery/Spotify tmux scripts.
- Remote: `git@github.com:thepavangollapalli/dotfiles.git`
