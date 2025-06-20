# Utils Workspace

This workspace contains a collection of utility scripts and configuration files for shell productivity, HDF5 data handling, and environment setup.

---

## HDF5 Utilities: [`dxl_hd5.py`](./dxl_hd5.md) -- WORK IN PROGRESS

### This is for my fellow students at Drexel ICE Lab only and will not mean anything to anyone else
**Command-line tool for inspecting, extracting, and exporting groups and datasets from HDF5 files.**

- [Full Documentation & Usage →](./dxl_hd5.md)
- Features: structure exploration, group/dataset export, 2D dataset to CSV, robust CLI, and more.
- Quick start:
  ```sh
  python src/dxl_hd5.py -i data/03.h5 --show STRUCTURE
  python src/dxl_hd5.py -i data/03.h5 --dump_all_groups
  ```
- See [`dxl_hd5.md`](./dxl_hd5.md) for setup, arguments, and detailed examples.

---

## Alias File ([`alias`](./alias))

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

See the [`alias`](./alias) file for full details and descriptions.

---

## Global Gitignore ([`global.gitignore`](./global.gitignore))

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
## install_bu Function

### Purpose
Installs the Bazinga Labs utility framework (bu) by cloning the repository into the user's work directory.
The [Bazinga Labs' Bash Utility framework](https://github.com/bazinga-labs/bu) provides a collection of productivity tools and scripts for development environments.
### Functionality
- Creates the `~/work` directory if it doesn't exist
- Clones the Bazinga Labs 'bu' repository into `~/work/bu` if not already present
- Provides instructions for configuring shell environment to use the bu utilities