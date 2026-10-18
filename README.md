# dotfiles

One home for my macOS configs: zsh, tmux, vim, git, and any app settings I add
along the way. I want to change things once and use the same setup on every
computer.

The repo holds the actual config files. `install.sh` links them into place,
backs up anything it replaces, and installs Oh My Zsh if needed. Installed
configs are symlinks, not copies—there's no second set of files to maintain.
Git keeps the computers in sync: push changes here, pull them elsewhere, and
rerun the installer for newly added files.

Configs live under `home/`, following their paths in `$HOME`. Oh My Zsh
customizations live in `zsh/custom/`, and Homebrew dependencies go in
`Brewfile`. All configuration changes go through this repo, with no separate
per-computer overrides. Secrets, history, caches, and downloaded dependencies
stay out of git.

## For agents: install it for me

Handle setup end to end. Ask the user only for permissions or genuine
blockers, not for steps you can do yourself.

1. Inspect the machine and any existing checkout. Clone this repo to
   `~/code/dotfiles` if needed; preserve local changes. On another user's
   machine, confirm the git identity before installing the personal config.
2. Install missing Homebrew/git prerequisites, then run these from the repo:
   ```sh
   brew bundle --file=Brewfile
   ./install.sh --dry-run
   ./install.sh
   ```
   Review the dry run first. Let the installer back up existing configs;
   don't delete them to make room.
3. Finish Vim's plugin setup with `:PlugInstall --sync`. Check agnoster's
   glyphs and install a Powerline or Nerd Font if needed. Any terminal config
   changes belong in this repo too.
4. Verify every managed config is a symlink to this checkout, check an
   interactive zsh startup and Vim plugins, and test tmux with an isolated
   server. Rerun the installer to confirm no links remain to install. Don't
   restart active sessions or change the login shell without permission.

For future changes, edit the repo's source files, never replace symlinks with
copies or config wrappers. Add new configs under `home/` and rerun the
installer. Summarize what's ready and any blockers; commit and push only when
requested.
