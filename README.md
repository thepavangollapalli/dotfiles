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
the external passion theme into its `themes/` directory, autosuggestions and
syntax highlighting into its `plugins/` directory, NVM into `~/.nvm`, and TPM
and tmux-resurrect into `~/.tmux/plugins`. Homebrew dependencies go in
`Brewfile`. Shared configuration changes go through this repo. Secrets,
history, caches, and downloaded dependencies stay out of git.

## Zsh theme

The shared `.zshrc` selects the external
[`passion` theme](https://github.com/ChesterYue/ohmyzsh-theme-passion), with timestamps,
the current directory, Git branch, colored chevrons, and command timings.
It uses `gdate` from `coreutils` and `bc`, both included in `Brewfile`.
After installing, open a new zsh session or run `exec zsh -l` to load it in
the current terminal.
The installer leaves running shells alone.

Passion is not bundled with Oh My Zsh. The installer downloads its theme file
to `~/.oh-my-zsh/custom/themes/passion.zsh-theme` and skips it when already
present. If startup prints `[oh-my-zsh] theme 'passion' not found`, rerun
`./install.sh` before opening a new shell. The theme stays out of git along
with the other downloaded dependencies.

If a fresh zsh session still shows the old prompt, run these in that session:

```zsh
print -r -- "zsh: $ZSH_VERSION" "config directory: ${ZDOTDIR:-$HOME}"
ls -l "${ZDOTDIR:-$HOME}/.zshrc"
print -r -- "theme: $ZSH_THEME"
```

The `.zshrc` should link to this checkout's `home/.zshrc`, and the theme should
be `passion`. The installer links `~/.zshrc`; if `ZDOTDIR` points elsewhere,
zsh reads its startup files from that directory instead. If the chevrons look
wrong, select a font that supports them in the terminal's font settings.

## Computer-specific credentials

Keep credentials and computer-specific authentication settings in
`~/.config/zsh/credentials.zsh`, outside this checkout. Both `.zprofile` and
`.zshrc` load the shared `~/.config/zsh/environment.zsh`, which sources this
optional private file after the shared environment defaults. The private
file should contain environment exports only, since login interactive shells
load it twice. Use `$HOME` instead of hardcoded user paths.

Store credentials needed across projects, key paths and passphrases, and
local credential profile names here. Keep reusable paths, aliases, and tool
setup in the repo rather than creating general per-computer config overrides.
Project commands belong in the project's Taskfile. Project environment
defaults and credentials belong in its supported environment files or tooling,
not global shell exports. Prefer credential manager references over storing
secret values when the tool supports them.
Create the private file with permissions `600`; never commit its contents or
print secret values during setup. The installer never creates, backs up, or
replaces this file. `credentials.zsh` is ignored as an additional safeguard.

Before replacing an existing configuration, move shared credentials into this
private file and project settings into the corresponding project's local
configuration. Preserve existing values without overwriting that project's
settings. This includes reviewing database connections, API tokens, and
private Go module settings currently exported by the old startup files.

## History and session restore

Zsh uses `~/.zhistory`. When migrating from `~/.zsh_history`, preserve the old
file and import its history before switching shells; the installer does not
copy or merge history. History limits belong in `.zshrc`, after macOS's
system startup files. NVM automatically selects the nearest `.nvmrc` on
directory changes and installs its Node version if missing.

Tmux uses `C-a` as its prefix. Save sessions with prefix + `Ctrl-s` and restore
them with prefix + `Ctrl-r` through tmux-resurrect.

Each pane retains up to 50,000 lines of scrollback. At the shell, scroll up
with the mouse wheel to browse that pane's history. Mouse-aware apps such as
Codex receive wheel events for their own scrolling. To browse tmux history
while an app is running, press prefix + `[` first; the wheel then scrolls
tmux history. Scroll back to the bottom or press `q` to return to the app.

Mouse-aware apps also receive clicks and drags for their own text selection.
At the shell, or after entering tmux history with prefix + `[`, click and drag
to select text through tmux; releasing copies it to the macOS clipboard and
keeps your scroll position. Press `q` to return to live output.

Press prefix + `/`, type a search, and press Enter to search backward through
the pane's history. In scrollback, `?` searches backward, `/` searches forward,
and `n` / `N` repeat the search in the same / opposite direction. Prefix + `[`
also enters scrollback using the keyboard; Space begins a selection and `y`
or Enter copies it and returns to live output. History is held in memory for
the pane's lifetime, so closed panes and server restarts lose it.

Reload these settings in an existing session with prefix + `r`.

## Agent window status

With agentfiles installed, tmux shows a rotating spinner beside a window's topic
while Claude Code, Codex, or Cursor works. When a turn finishes or an agent asks
for input, the label turns amber and gains `ℹ`. Selecting the window or returning
terminal focus dismisses that notice. Sending another prompt restores
the working indicator. Windows without an agent keep their normal styling.

State belongs to each pane: any waiting agent makes the window amber, while any
running agent keeps its spinner moving. Moving or closing a pane carries or
removes its state. Returning to a Zsh prompt clears stale state after a CLI exits.
The spinner uses tmux 3.8's native animation format, with no background poller.

Dotfiles owns the status formatting and shell cleanup; agentfiles owns the
harness lifecycle hooks. After updating agentfiles, reinstall its generated
configuration and restart harnesses. Review new Codex hooks through `/hooks`.
Cursor's completion hook marks completed turns; it has no dedicated hook for
mid-turn approval prompts. To check the display on an isolated tmux server, run
`python3 -B -m unittest discover -s tests -p 'test_tmux_agent_status.py'`.

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
3. Finish Vim's plugin setup with `:PlugInstall --sync`. Check passion's
   chevrons and the terminal's font and colors. Any terminal config
   changes belong in this repo too.
4. Verify every managed config is a symlink to this checkout, check an
   interactive zsh startup and Vim plugins, and test tmux with an isolated
   server. Rerun the installer to confirm no links remain to install. Don't
   restart active sessions or change the login shell without permission.

For future changes, edit the repo's source files, never replace symlinks with
copies or config wrappers. Add new configs under `home/` and rerun the
installer. Summarize what's ready and any blockers; commit and push only when
requested.
