# dotfiles

My macOS setup for zsh, tmux, vim, and git. This repo is the source of truth
for configuration—edit it here, not in scattered files around `$HOME`.
Installed config files are symlinks to this checkout, never separate copies.

## Get started

```sh
git clone git@github.com:thepavangollapalli/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
brew bundle --file=Brewfile
./install.sh
exec zsh -l
```

You'll need Homebrew and git. The installer links configs into `$HOME`, backs
up existing files to `~/.dotfiles-backup/`, and installs Oh My Zsh if needed.
It's safe to rerun; use `./install.sh --dry-run` to preview changes.

## What's here

- **zsh** — Oh My Zsh with the agnoster theme, plugins, vi mode, and aliases.
  Custom themes and plugins go in `zsh/custom/`. Agnoster looks best with a
  Powerline or Nerd Font.
- **tmux** — `C-a` prefix, vi-style copy mode, mouse, and useful splits.
- **vim** — vim-plug and a small set of plugins; they install on first launch.
- **git** — personal settings, aliases, and global ignores.

Keep secrets, SSH keys, history, caches, and downloaded dependencies out of git.

## One set of configs, every computer

Install this repo on each computer. Edit the source files once, commit and
push, then sync the other computers:

```sh
cd ~/code/dotfiles
git pull --ff-only
./install.sh
```

Existing symlinks pick up edits immediately; rerunning the installer links
new files. Reload the affected app when needed. Git syncs the checkouts—it
doesn't automatically update other computers. Don't keep local config copies
or per-computer overrides.

## Add a config

All config changes go through this repo, including app settings under
`~/.config`. Add files under `home/` using their path relative to `$HOME`,
then run `./install.sh`. For example:

```sh
mkdir -p home/.config/foo
cp ~/.config/foo/bar.conf home/.config/foo/bar.conf
./install.sh
```

## For agents: install it for me

Handle setup end to end. Don't hand the user a checklist when you can do the
work yourself.

1. Inspect the machine and any existing checkout first. Use `~/code/dotfiles`
   by default; don't overwrite local changes or unrelated configs.
2. Install missing prerequisites, then run `brew bundle --file=Brewfile` from
   the repo. If Homebrew or Apple's command-line tools need interactive
   approval, ask only for that step and continue afterward. On another user's
   machine, confirm the git identity before installing the personal config.
3. Run `./install.sh --dry-run`, review the replacements, then run
   `./install.sh`. Use its backups—don't delete the old setup to make room.
   Every managed config path must be a symlink to its source in this checkout,
   not a copied file or a wrapper that sources another config.
4. Finish Vim's plugin setup, rather than leaving it for the user's first
   launch. Run `:PlugInstall --sync` in Vim and check that it succeeds. Make
   sure agnoster's glyphs render; install a suitable font if needed and keep
   any terminal settings in this repo too.
5. Verify the symlinks, an interactive zsh startup, Vim plugins, and tmux
   config using an isolated test server. Rerun the installer to confirm
   nothing else needs linking. Don't restart active sessions or change the
   login shell without permission.

For future changes, edit only the repo's source files. Never replace installed
symlinks with regular files or create separate per-machine configs. Rerun the
installer for new files; existing links already reflect source edits.
Bring new configs into `home/` before changing them; keep OMZ customizations
in `zsh/custom/` and dependencies in `Brewfile`. Never commit secrets or
machine-generated data. Summarize what's ready and any blockers; commit and
push only when requested.
