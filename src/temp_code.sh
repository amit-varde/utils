#!/bin/bash
#---------------------------------------------------------------------------------------------------
# This is for temp code of quick bash functions
#---------------------------------------------------------------------------------------------------
search_bash_functions() {   # Build a list of functions and aliases from ./src/utils_*.sh; filter by search term if provided
    local search_term="$1"
    local util_files=(./src/utils_*.sh)
    if [ ${#util_files[@]} -eq 0 ]; then
        echo "No utility files found in ./src/"
        return 1
    fi
    
    for file in "${util_files[@]}"; do
        echo "File: $(basename "$file")"
        echo "Functions:"
        local funcs
        funcs=$(list_bash_functions_in_file "$file")
        if [ -n "$search_term" ]; then
            echo "$funcs" | grep -i --color=never "$search_term" | sed -E "s/($search_term)/\033[1;31m\1\033[0m/Ig"
        else
            echo "$funcs"
        fi
        echo "Aliases:"
        local aliases
        aliases=$(list_alias_in_file "$file")
        if [ -n "$search_term" ]; then
            echo "$aliases" | grep -i --color=never "$search_term" | sed -E "s/($search_term)/\033[1;31m\1\033[0m/Ig"
        else
            echo "$aliases"
        fi
        echo "---------------------------------------------"
    done
}
search_bash_functions "git"