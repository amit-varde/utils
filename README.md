Add the following lines in your ~/.zshrc

```
################################################################################
# Let this always be the last line
alias so='source ~/.zshrc;echo "ZSH aliases sourced."'
ALIAS_FILE="$HOME/work/utils/alias"
if [ -f "$ALIAS_FILE" ]; then
  source "$ALIAS_FILE"
else
  echo "Alias file $ALIAS_FILE not found"
fi
################################################################################
```

# bu  - Bash Utilities
The Bash Utilities framework provides a modular system for organizing and managing shell functions across specialized domains. Built around a core loading mechanism in util_bash.sh, the framework enables dynamic loading and unloading of utility modules like util_git.sh and util_pkgs.sh, each containing related functions following a consistent documentation pattern. Each function includes descriptive inline comments and follows naming conventions that support easy discoverability through the bu_functions command. The system provides consistent error handling and colorized output through shared helper functions (err, warn, info). Users can manage utilities with commands like bu_load, bu_unload, bu_list, and bu_list_loaded, making it easy to maintain a clean environment while accessing only needed functionality. Utilities can be extended by creating new files following the documented structure pattern, with automatic function registration through the list_bash_functions_in_file 
mechanism.

## util_bash.sh
This file provides core utility functions for loading, listing, and managing bash utility scripts within the framework. It standardizes output formatting and supports dynamic utility loading/unloading.


## file:util_git.sh

This file contains a collection of helper functions for interacting with Git repositories, such as comparing local files to their remote counterparts, displaying file version history, and managing stashes. It integrates with the bash utility framework for consistent usage.


## file:util_pkgs.sh

This file offers functions for managing Python development environments, including virtual environment creation, pip package version reporting, and Homebrew package management. It helps automate package environment tasks and is part of the overall utility suite.

# fu- File Utilitiees
The File Utilities (fu) module provides specialized tools for working with various file formats
Working on #ppts for now