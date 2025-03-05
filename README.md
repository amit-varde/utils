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
