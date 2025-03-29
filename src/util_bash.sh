# -----------------------------------------------------------------------------
# File: util_bash.sh
# Author: Amit
# -----------------------------------------------------------------------------
# Description:
# This file contains utility functions for loading and managing bash utilities.
# -----------------------------------------------------------------------------

load_bash_util() {   # Load a specified bash utility
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
list_bash_utils() {   # Display loaded bash utilities
    # Check if -a parameter is provided to list all available utilities
    if [ "$1" = "-a" ]; then
        echo "All available BASH utilities:"
        # Shift the arguments to use $2 as the search term if provided
        shift
        # Find all utility files in BASH_UTILS_SRC
        find "$BASH_UTILS_SRC" -name "util_*.sh" 2>/dev/null | while read -r util_path; do
            # Extract util name by removing prefix and suffix
            util_name=$(basename "$util_path" | sed 's/^util_//;s/\.sh$//')
            # Filter by search term if provided
            if [ -z "$1" ] || echo "$util_name" | grep -q "$1" || echo "$util_path" | grep -q "$1"; then
                echo "$util_name : $util_path"
            fi
        done
        return
    fi
    
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
