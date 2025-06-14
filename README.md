## Alias File (`alias`)

This file contains a collection of useful shell aliases and functions for everyday tasks. To use these aliases, add the following to the end of your `~/.zshrc`:

```zsh
# Let this always be the last line
alias so='source ~/.zshrc;echo "ZSH aliases sourced."'
ALIAS_FILE="$HOME/work/utils/alias"
if [ -f "$ALIAS_FILE" ]; then
  source "$ALIAS_FILE"
else
  echo "Alias file $ALIAS_FILE not found"
fi
```

### Highlights
- Directory navigation: `w`, `docs`, `dl`, `idl`, `idoc`, `up`
- File listing: `lr`, `la`, `l1`
- Permissions: `lock`, `unlock`, `mkexe`
- Terminal: `x`, `c`, `cls`
- File viewing: `m`, `h`, `t`
- Grep: `g`
- Clean temp files: `clean-temp-files`
- Misc: `fname`, `dname`, `mde`, `open` (VSCode aware)
- Loads bash utility functions if available
- Functions for setting up Graphviz and Git environments
- Pyenv initialization

See the `alias` file for full details and descriptions.

---

## Global Gitignore (`global.gitignore`)

This file is intended to be used as your global gitignore. It excludes common files and directories that should not be tracked by git, such as:

- Python cache and bytecode: `*.pyc`, `__pycache__/`
- IDE and editor files: `.idea/`, `.vscode/`, `.history/`, `.ionide/`, `.vs/`, `*.vsix`, `*.code-workspace`
- Node and Python environments: `node_modules/`, `venv/`, `run/`, `out/`
- macOS and backup files: `.DS_Store`, `*~`, `.*~`, `*.swp`, `*.swo`, `*.bak`, `*.tmp`, `*.orig`, `*.rej`
- Project-specific: `summary.txt`, `.alias.swp`

To use as your global gitignore:

```sh
git config --global core.excludesfile ~/work/utils/global.gitignore
```

---

### Git Setup Function: `setup_my_git()`

This function configures your global Git environment with preferred settings and identity. It is included in the `alias` file and can be run in your shell:

- Sets your name, email, and GitHub user for all repositories
- Points your global gitignore to `~/.gitignore`
- Sets Vim as the default editor and enables colored UI
- Sets push default to `simple`
- Caches credentials for 1 hour
- Automatically generates an SSH key (`~/.ssh/id_ed25519`) if missing, using your email and hostname for the comment

To use, simply run:

```sh
setup_my_git
```

This will ensure your Git environment is ready for use with your identity and best practices.