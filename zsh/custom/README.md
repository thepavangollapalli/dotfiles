# Custom oh-my-zsh content

`~/.zshrc` sets `ZSH_CUSTOM` to this directory, so anything here is versioned
with the rest of the dotfiles.

- `themes/<name>.zsh-theme` — custom themes; set `ZSH_THEME="<name>"` in `.zshrc`
- `plugins/<name>/<name>.plugin.zsh` — custom plugins; add `<name>` to the
  `plugins=(...)` list in `.zshrc`
- `*.zsh` at this level — loaded automatically by oh-my-zsh on startup

Third-party plugins (e.g. zsh-autosuggestions) can be cloned into `plugins/`.
If you do that, either commit the plugin or add it to the repo's `.gitignore`.
