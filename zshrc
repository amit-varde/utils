# zshrc-modified by
# Amit Varde
# 28-Feb-2025
#
################################################################################
# Standard Exports
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH="/usr/local/opt/graphviz/bin:$PATH"
export LANG=en_US.UTF-8
################################################################################


################################################################################
# PROMPT Customization
PROMPT="%n@%m:%~> "
################################################################################

################################################################################
# ZSH Settings
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh
export ZSH="$HOME/.oh-my-zsh"
################################################################################



################################################################################
# Let this always be the last line
alias so='source ~/.zshrc;echo "ZSH aliases sourced."'
UTILS="/Users/amit/work/utils"
if [ -f "$UTILS/alias" ]; then
  source "$UTILS/alias"
fi
################################################################################
