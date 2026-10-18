# dotfiles

My macOS setup, kept simple: configs live here and `install.sh` links them into
my home directory. Oh My Zsh is installed separately; its settings and custom
themes or plugins live in this repo.

## Get started

```sh
git clone git@github.com:thepavangollapalli/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./install.sh --dry-run  # preview changes
./install.sh
```

The installer backs up anything it replaces to `~/.dotfiles-backup/` and is
safe to run again. It also installs Oh My Zsh if needed. Open a new terminal
or run `exec zsh -l` when it's done.

## What's here

- **zsh** — Oh My Zsh with the agnoster theme, plugins, vi mode, and aliases.
  Custom themes and plugins go in `zsh/custom/`. Agnoster looks best with a
  Powerline or Nerd Font.
- **tmux** — `C-a` prefix, vi-style copy mode, mouse, and useful splits.
- **vim** — vim-plug and a small set of plugins; they install on first launch.
- **git** — personal settings, aliases, and global ignores.

Command history, SSH keys, and app settings under `~/.config` aren't managed
here.

## Add a config

Put the file under `home/` at the same relative path it has in `$HOME`, then
run `./install.sh`. For example:

```sh
cp ~/.config/foo/bar.conf home/.config/foo/bar.conf
./install.sh
```
