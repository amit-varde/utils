#!/bin/bash
# -----------------------------------------------------------------------------
# File: util_pkgs.sh
# Author: Amit
# Email: tercel04@gmail.com; amit@bazinga-labs.com
# -----------------------------------------------------------------------------
# Description:
#  Utilities for managing Python environments and package installations.
#  Provides tools for virtual environment setup, package version reporting.
#  Includes helpers for pip, brew, and pyenv with update notifications.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
init_venv() { # Initialize and activate a Python virtual environment
    if [ -d "venv" ]; then
        echo "Virtual environment already exists in the current directory."
        read -p "Do you want to recreate it? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Operation canceled."
            return 1
        fi
        rm -rf venv
        echo "Existing virtual environment removed."
    fi
    python -m venv venv
    if [ $? -eq 0 ]; then
        echo "Virtual environment created successfully."
        source venv/bin/activate
        echo "Virtual environment activated."
    else
        echo "Failed to create virtual environment."
        return 1
    fi
}

# -----------------------------------------------------------------------------
pip_versions_report() { # Generate a report of installed pip packages and versions
    echo "Package, Installed Version, Latest Version, Status" | column -t -s ','
    installed_packages=$(pip list --format=freeze)
    while IFS= read -r package_info; do
        package=$(echo "$package_info" | cut -d'=' -f1)
        installed_version=$(echo "$package_info" | cut -d'=' -f3)
        latest_version=$(pip index versions "$package" 2>&1 | grep -o 'Available versions:.*' | cut -d':' -f2 | awk '{print $1}')
        if [ "$installed_version" == "$latest_version" ]; then
            status="UP_TO_DATE"
        else
            status="NEEDS_UPGRADE"
        fi
        echo "$package, $installed_version, $latest_version, $status"
    done <<< "$installed_packages" | column -t -s ','
}

# -----------------------------------------------------------------------------
clean_brew_cache() { # Clear Homebrew cache
    brew cleanup -s
    echo "Homebrew cache cleared."
}

# -----------------------------------------------------------------------------
clean_pip_cache() { # Clear pip cache
    pip cache purge
    echo "Pip cache cleared."
}
alias clean-pip-cache='pip cache purge'  # Clear pip cache

# -----------------------------------------------------------------------------
pip_diff_requirements() { # Compare temporary requirements file with requirements.txt using diff
    local req_file="requirements.txt"
    local temp_req_file="tmp_requirements.txt"
    if [ ! -f "$req_file" ]; then
        echo "Error: Requirements file '$req_file' does not exist."
        return 1
    fi
    if [ -f "$temp_req_file" ]; then
        echo "Error: Temporary requirements file '$temp_req_file' already exists."
        return 1
    fi
    echo "Comparing '$temp_req_file' with '$req_file'..."
    code --diff "$temp_req_file" "$req_file"
}

# -----------------------------------------------------------------------------
pip_overwrite_requirements_file() { # Overwrite requirements file with a backup
    local req_file="requirements.txt"
    local tmp_req_file="tmp_requirements.txt"
    local backup_dir=".backup_requirements.txt"
    local date=$(date +"%Y%m%d_%H%M%S")

    [ ! -f "$req_file" ] && { echo "Error: Requirements file '$req_file' does not exist."; return 1; }
    [ ! -f "$tmp_req_file" ] && { echo "Error: Temporary requirements file '$tmp_req_file' does not exist."; return 1; }
    mkdir -p "$backup_dir"
    my "$req_file" "$backup_dir/requirements_$date.txt"
    [ $? -eq 0 ] && echo "Backup created at '$backup_dir/requirements_$date.txt'." || { echo "Failed to create backup."; return 1; }
    echo "Overwriting '$req_file'..."
    mv "$tmp_req_file" "$req_file"
    [ $? -eq 0 ] && echo "'$req_file' has been overwritten successfully." || { echo "Failed to overwrite '$req_file'."; return 1; }
}

# -----------------------------------------------------------------------------
brew_versions_report() { # Generate a report of installed Homebrew packages and versions
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required. Install it using: brew install jq"
        return 1
    fi
    echo "Package, Installed Version, Latest Version, Status"
    info=$(brew info --json=v2 --installed)
    installed_versions=$(echo "$info" | jq -r '.formulae[] | .name + "," + (.installed[0].version // "Not Installed")')
    latest_versions=$(echo "$info" | jq -r '.formulae[] | .name + "," + (.versions.stable // "Unknown")')
    while IFS= read -r installed; do
        package=$(echo "$installed" | cut -d',' -f1)
        installed_version=$(echo "$installed" | cut -d',' -f2)
        latest_version=$(echo "$latest_versions" | grep "^$package," | cut -d',' -f2)
        if [ "$installed_version" == "$latest_version" ]; then
            status="UP_TO_DATE"
        else
            status="NEEDS_UPGRADE"
        fi
        echo "$package, $installed_version, $latest_version, $status"
    done <<< "$installed_versions" | column -t -s ','
}

# -----------------------------------------------------------------------------
# Aliases related to pip, virtualenv, brew, and pyenv
alias initvenv='init_venv'
alias pip-report='pip_versions_report'
alias pip-diff='pip_diff_requirements'
alias pip-overwrite='pip_overwrite_requirements_file'
alias brew-report='brew_versions_report'
alias pyenv-info='pyenv versions'
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# If loading is successful this will be executed
# Always makes sure this is the last function call
type list_bash_functions_in_file >/dev/null 2>&1 && list_bash_functions_in_file "$(realpath "$0")" || echo "Error: alias is not loaded"
# -----------------------------------------------------------------------------