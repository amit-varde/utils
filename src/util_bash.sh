# -----------------------------------------------------------------------------
# File: util_bash.sh
# Author: Amit
# -----------------------------------------------------------------------------
# Description: This file contains utility functions for loading and managing bash utilities.
# -----------------------------------------------------------------------------

# Check if BASH_UTILS_SRC is defined
if [ -z "$BASH_UTILS_SRC" ]; then
    echo "Error: BASH_UTILS_SRC is not defined. This variable must point to the directory containing utility scripts."
    return 1 2>/dev/null || exit 1
fi

# Export environment variable to track loaded utilities
export BASH_UTILS_LOADED=${BASH_UTILS_LOADED:-""}

# -----------------------------------------------------------------------------
list_bash_functions_in_file() {   # List all function definitions in a file with descriptions
    local script_path="$1"
    echo "Functions defined in [$(basename "$script_path")]: "
    
    # Use grep to find function definitions that include an inline comment for description
    fs=$(grep -E '^[a-zA-Z0-9_]+\(\)\ *\{\ *#' "$script_path")
    
    # Find the maximum length of function names for proper alignment
    max_len=0
    while IFS= read -r line; do
        # Extract function name (removing parentheses and braces)
        func_name=$(echo "$line" | sed -E 's/^([a-zA-Z0-9_]+)\(\).*$/\1/' | xargs)
        if [ ${#func_name} -gt $max_len ]; then
            max_len=${#func_name}
        fi
    done <<< "$fs"
    
    # Print function names with aligned descriptions
    while IFS= read -r line; do
        func_name=$(echo "$line" | sed -E 's/^([a-zA-Z0-9_]+)\(\).*$/\1/' | xargs)
        description=$(echo "$line" | sed 's/.*#//')
        printf " %-${max_len}s :%s\n" "$func_name" "$description"
    done <<< "$fs"
}
# -----------------------------------------------------------------------------
list_alias_in_file() {   # List all alias definitions in this file with descriptions
    local script_path="$1"
    echo "Aliases defined in [$(basename "$script_path")]: "
    # Use grep to find alias definitions that include an inline comment for description
    as=$(grep -E '^alias [^=]+=.*#' "$script_path")
    # Find the maximum length of alias names
    max_len=0
    while IFS= read -r line; do
        # Extract alias name located between 'alias' and the '=' sign
        alias_name=$(echo "$line" | sed -E 's/^alias[[:space:]]+([^=]+)=.*$/\1/' | xargs)
        if [ ${#alias_name} -gt $max_len ]; then
            max_len=${#alias_name}
        fi
    done <<< "$as"
    
    # Print alias names with aligned descriptions
    while IFS= read -r line; do
        alias_name=$(echo "$line" | sed -E 's/^alias[[:space:]]+([^=]+)=.*$/\1/' | xargs)
        description=$(echo "$line" | sed 's/.*#//')
        printf " %-${max_len}s :%s\n" "$alias_name" "$description"
    done <<< "$as"
}
# -----------------------------------------------------------------------------
bu_list() {   # Display loaded bash utilities
    # If no arguments or -a parameter is provided, list all available utilities
    if [ "$#" -eq 0 ] ; then
        echo "All available BASH utilities:"
        # Find all utility files in BASH_UTILS_SRC
        ls -1 "$BASH_UTILS_SRC"/util_*.sh 2>/dev/null | while read -r util_path; do
            # Extract util name by removing prefix and suffix
            util_name=$(basename "$util_path" | sed 's/^util_//;s/\.sh$//')
            # Extract description from the utility file
            util_description="NA"; [ -f "$util_path" ] && desc=$(grep -m 1 "# Description:" "$util_path" | sed 's/# Description://' | xargs) && [ -n "$desc" ] && util_description="$desc"
            # Filter by search term if provided
            if [ -z "$1" ] || echo "$util_name" | grep -q "$1" || echo "$util_path" | grep -q "$1"; then
                #echo "$util_name : $util_description : $util_path"
                echo "$util_name : $util_description"
            fi
        done
        return
    fi
    # If we get here, user provided a search term but not -a flag, so show loaded utilities
    echo "Loaded BASH utilities:"
    [ -z "$BASH_UTILS_LOADED" ] && echo "$ICON_RED_CROSS No utilities currently loaded." && return
    # Process each utility
    echo "$BASH_UTILS_LOADED" | tr ":" "\n" | while read -r util; do
        [ -z "$util" ] && continue  # Skip empty entries
        util_path="$BASH_UTILS_SRC/util_${util}.sh"
        
        # Check if utility file still exists
        if [ -f "$util_path" ]; then
            # If search term provided, filter results
            if [ -z "$1" ] || echo "$util" | grep -q "$1" || echo "$util_path" | grep -q "$1"; then
                echo "$ICON_GREEN_CHECK $util: $util_path"
            fi
        else
            # If search term provided, filter results
            if [ -z "$1" ] || echo "$util" | grep -q "$1" || echo "$util_path" | grep -q "$1"; then
                echo "$ICON_RED_CROSS $util: $util_path (FILE MISSING)"
            fi
        fi
    done
}
# -----------------------------------------------------------------------------
bu_load() {   # Load a specified bash utility
    local util_name="$1"
    local util_path="$BASH_UTILS_SRC/util_${util_name}.sh"
    
    # Check if utility name was provided
    [ -z "$util_name" ] && { echo "$ICON_RED_CROSS Error: No utility name specified."; return 1; }
    # Check if utility file exists
    [ ! -f "$util_path" ] && { echo "$ICON_RED_CROSS Error: Utility '$util_name' not found at $util_path"; return 1; }
    
    # Source the utility file
    source "$util_path"
    # Check if sourcing was successful
    if [ $? -eq 0 ]; then
        # Append to the list of loaded utilities if not already in the list
        if [[ "$BASH_UTILS_LOADED" != *"$util_name"* ]]; then
            if [ -z "$BASH_UTILS_LOADED" ]; then
                BASH_UTILS_LOADED="$util_name"
            else
                BASH_UTILS_LOADED="$BASH_UTILS_LOADED:$util_name"
            fi
        fi
        echo "$ICON_GREEN_CHECK Utility '$util_name' loaded successfully."
        return 0
    else
        echo "$ICON_RED_CROSS Error loading utility '$util_name'."
        return 1
    fi
}
# -----------------------------------------------------------------------------
bu_unload() {   # Unload a specified bash utility and remove its functions
    local util_name="$1"
    local util_path="$BASH_UTILS_SRC/util_${util_name}.sh"
    
    # Check if utility name was provided
    [ -z "$util_name" ] && { echo "$ICON_RED_CROSS Error: No utility name specified."; return 1; }
    
    # Check if the utility is currently loaded
    if [[ "$BASH_UTILS_LOADED" != *"$util_name"* ]]; then
        echo "$ICON_WARNING Utility '$util_name' is not currently loaded."
        return 1
    fi
    
    # Check if utility file exists
    if [ ! -f "$util_path" ]; then
        echo "$ICON_WARNING Utility file '$util_path' not found, but will attempt to unload from memory."
    fi
    
    echo "Unloading utility '$util_name'..."
    
    # Get all function names from the utility file
    local fs=""
    if [ -f "$util_path" ]; then
        # Extract functions with their descriptions
        fs=$(grep -E '^[a-zA-Z0-9_]+\(\)\ *\{\ *#' "$util_path")
    else
        echo "$ICON_WARNING Cannot extract function names from missing file. Manual cleanup might be needed."
        return 1
    fi
    # Calculate maximum function name length for formatting
    local max_len=0
    while IFS= read -r line; do
        # Extract function name (before #) and remove (), {}
        local func_name=$(echo "$line" | sed 's/#.*$//' | tr -d '(){}' | xargs)
        if [ ${#func_name} -gt $max_len ]; then
            max_len=${#func_name}
        fi
    done <<< "$fs"
    # Unset each function and print what was unset
    echo "Unsetting functions from utility '$util_name':"
    while IFS= read -r line; do
        local func_name=$(echo "$line" | sed 's/#.*$//' | tr -d '(){}' | xargs)
        local description=$(echo "$line" | sed 's/^[^#]*#//')
        
        # Attempt to unset the function
        unset -f "$func_name" 2>/dev/null
        local unset_status=$?
        
        # Report the result
        if [ $unset_status -eq 0 ]; then
            printf " %-${max_len}s :%-40s [UNSET]\n" "$func_name" "$description"
        else
            printf " %-${max_len}s :%-40s [FAILED]\n" "$func_name" "$description"
        fi
    done <<< "$fs"
    
    # Update the BASH_UTILS_LOADED variable to remove this utility
    local new_loaded=""
    for loaded_util in $(echo "$BASH_UTILS_LOADED" | tr ":" " "); do
        if [ "$loaded_util" != "$util_name" ]; then
            if [ -z "$new_loaded" ]; then
                new_loaded="$loaded_util"
            else
                new_loaded="$new_loaded:$loaded_util"
            fi
        fi
    done
    # Set the updated list of loaded utilities
    BASH_UTILS_LOADED="$new_loaded"
    echo "$ICON_GREEN_CHECK Utility '$util_name' unloaded successfully."
    return 0
}

# Create aliases for backwards compatibility
alias list_bash_utils='bu_list'
alias load_bash_util='bu_load'
alias unload_bash_utils='bu_unload'
# -----------------------------------------------------------------------------
