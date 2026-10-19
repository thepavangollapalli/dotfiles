# dotfiles

One home for my macOS configs: zsh, tmux, vim, git, and any app settings I add
along the way. I want to change things once and use the same setup on every
computer.

The repo holds the actual config files. `install.sh` links them into place,
backs up anything it replaces, and installs missing shell and tmux dependencies.
Installed configs are symlinks, so there's no second set of files to maintain.
Git keeps the computers in sync: push changes here, pull them elsewhere, and
rerun the installer for newly added files.

Configs live under `home/`, following their paths in `$HOME`. Oh My Zsh uses
its default custom directory, `~/.oh-my-zsh/custom`. The installer downloads
autosuggestions and syntax highlighting there, NVM into `~/.nvm`, and TPM
and tmux-resurrect into `~/.tmux/plugins`. Homebrew dependencies go in
`Brewfile`. Shared configuration changes go through this repo. Secrets,
history, caches, and downloaded dependencies stay out of git.

## Computer-specific credentials

Keep credentials and computer-specific authentication settings in
`~/.config/zsh/credentials.zsh`, outside this checkout. Both `.zprofile` and
`.zshrc` load the shared `~/.config/zsh/environment.zsh`, which sources this
optional private file after the shared environment defaults. The private
file should contain environment exports only, since login interactive shells
load it twice. Use `$HOME` instead of hardcoded user paths.

Store tokens, key paths and passphrases, authenticated Snowflake connection
strings, and local credential profile names here. Keep reusable paths,
aliases, tool setup, and non-secret development defaults in the repo rather
than creating general per-computer config overrides. Prefer credential
manager references over storing secret values when the tool supports them.
Create the private file with permissions `600`; never commit its contents or
print secret values during setup. The installer never creates, backs up, or
replaces this file. `credentials.zsh` is ignored as an additional safeguard.

Before replacing an existing configuration, migrate its credential exports
into this private file. On this computer that includes `CHROMATIC_PROJECT_TOKEN`,
the `SNOWFLAKE_PRIVATE_KEY_*` and `*_SNOWFLAKE_DB_CONN_STRING` variables,
`AWS_MFA_PROFILE`, and `ONEPASS_AWS_CRED_NAME`.

## History and session restore

Zsh uses `~/.zhistory`. When migrating from `~/.zsh_history`, preserve the old
file and import its history before switching shells; the installer does not
copy or merge history. History limits belong in `.zshrc`, after macOS's
system startup files. NVM automatically selects the nearest `.nvmrc` on
directory changes and installs its Node version if missing.

Tmux uses `C-a` as its prefix. Save sessions with prefix + `Ctrl-s` and restore
them with prefix + `Ctrl-r` through tmux-resurrect.

## For agents: install it for me

Handle setup end to end. Ask the user only for permissions or genuine
blockers, not for steps you can do yourself.

1. Inspect the machine and any existing checkout. Clone this repo to
   `~/code/dotfiles` if needed; preserve local changes. On another user's
   machine, confirm the git identity before installing the personal config.
2. Preserve existing credentials and history as described above. Install
   missing Homebrew/git prerequisites, then run these from the repo:
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
