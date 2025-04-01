#!/bin/bash
# Install python-dotenv for .env file support
# -----------------------------------------------------------------------------
# File: setup_dev_env.sh
# Author: Amit
# -----------------------------------------------------------------------------
# Description:
# This script performs a fresh installation of Python development environment 
# on macOS, including Homebrew, pyenv, and .env file support.
# -----------------------------------------------------------------------------
# Usage:
# bash setup_dev_env.sh [OPTIONS]
#
# Options:
#   --install         Specify individual packages to install (homebrew, pyenv, python, pip, virtualenv, all)
#   --reinstall       Specify individual packages to reinstall (uninstall + install) (homebrew, pyenv, python, pip, virtualenv, all)
#   --repair          Specify individual packages to repair (homebrew, pyenv, python, pip, virtualenv, all)
#   --upgrade         Specify individual packages to upgrade (homebrew, pyenv, python, pip, virtualenv, all)
#   --log FILE        Direct all output to specified log file (while still showing on screen)
#                     Default: ~/.logs/<scriptname>.<date>
# -----------------------------------------------------------------------------

# Color definitions
RED="\033[1;31m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
ORANGE="\033[0;33m"  # Adding orange for warnings
RESET="\033[0m"

# Setup logging
LOG_FILE=""
LOGGING_ENABLED=false

# Set up default log file if not specified
setup_default_log() {
    # Extract script name without path
    local script_name=$(basename "$0")
    # Format current date
    local date_str=$(date +"%Y%m%d_%H%M%S")
    # Create default log path
    mkdir -p "$HOME/.logs" 2>/dev/null
    LOG_FILE="$HOME/.logs/${script_name}.${date_str}.log"
}

# Set up logging to file while still printing to screen
setup_logging() {
    local log_file="$1"
    # Create directory for log file if it doesn't exist
    local log_dir=$(dirname "$log_file")
    mkdir -p "$log_dir" 2>/dev/null || { err "Cannot create log directory: $log_dir"; exit 1; }
    
    # Check if log file can be created/written to
    touch "$log_file" 2>/dev/null || { err "Cannot write to log file: $log_file"; exit 1; }
    
    # Use 'tee' to redirect all output to both console and log file
    # Save original file descriptors
    exec 3>&1 4>&2
    # Create pipe to log file
    exec > >(tee -a "$log_file") 2>&1
    
    info "Logging output to: $log_file"
    LOGGING_ENABLED=true
}

# Helper functions for consistent output
err() {
    echo -e "${RED}Error: $*${RESET}" >&2
}

warn() {
    echo -e "${YELLOW}Warning: $*${RESET}" >&2
}

info() {
    echo -e "${BLUE}Info: $*${RESET}"
}

success() {
    echo -e "${GREEN}$*${RESET}"
}

# Initialize variables
INSTALL_HOMEBREW=false
INSTALL_PYENV=false
INSTALL_PYTHON=false
INSTALL_PIP=false
INSTALL_VIRTUALENV=false
REINSTALL_HOMEBREW=false
REINSTALL_PYENV=false
REINSTALL_PYTHON=false
REINSTALL_PIP=false
REINSTALL_VIRTUALENV=false
REPAIR_HOMEBREW=false
REPAIR_PYENV=false
REPAIR_PYTHON=false
REPAIR_PIP=false
REPAIR_VIRTUALENV=false
UPGRADE_HOMEBREW=false
UPGRADE_PYENV=false
UPGRADE_PYTHON=false
UPGRADE_PIP=false
UPGRADE_VIRTUALENV=false
ANY_TOOL_SELECTED=false

# Process command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --install)
            shift
            if [[ "$#" -eq 0 ]]; then
                err "Missing tool names for --install option"; exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
                case $1 in
                    all)
                        INSTALL_HOMEBREW=true
                        INSTALL_PYENV=true
                        INSTALL_PYTHON=true
                        INSTALL_PIP=true
                        INSTALL_VIRTUALENV=true
                        ;;
                    homebrew) INSTALL_HOMEBREW=true ;;
                    pyenv) INSTALL_PYENV=true ;;
                    python) INSTALL_PYTHON=true ;;
                    pip) INSTALL_PIP=true ;;
                    virtualenv) INSTALL_VIRTUALENV=true ;;
                    *) err "Unknown package: $1"; exit 1 ;;
                esac
                shift
            done
            continue
            ;;
        --reinstall)
            shift
            if [[ "$#" -eq 0 ]]; then
                err "Missing tool names for --reinstall option"; exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
                case $1 in
                    all)
                        REINSTALL_HOMEBREW=true
                        REINSTALL_PYENV=true
                        REINSTALL_PYTHON=true
                        REINSTALL_PIP=true
                        REINSTALL_VIRTUALENV=true
                        ;;
                    homebrew) REINSTALL_HOMEBREW=true ;;
                    pyenv) REINSTALL_PYENV=true ;;
                    python) REINSTALL_PYTHON=true ;;
                    pip) REINSTALL_PIP=true ;;
                    virtualenv) REINSTALL_VIRTUALENV=true ;;
                    *) err "Unknown package: $1"; exit 1 ;;
                esac
                shift
            done
            continue
            ;;
        --repair)
            shift
            if [[ "$#" -eq 0 ]]; then
                err "Missing tool names for --repair option"; exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
                case $1 in
                    all)
                        REPAIR_HOMEBREW=true
                        REPAIR_PYENV=true
                        REPAIR_PYTHON=true
                        REPAIR_PIP=true
                        REPAIR_VIRTUALENV=true
                        ;;
                    homebrew) REPAIR_HOMEBREW=true ;;
                    pyenv) REPAIR_PYENV=true ;;
                    python) REPAIR_PYTHON=true ;;
                    pip) REPAIR_PIP=true ;;
                    virtualenv) REPAIR_VIRTUALENV=true ;;
                    *) err "Unknown package: $1"; exit 1 ;;
                esac
                shift
            done
            continue
            ;;
        --upgrade)
            shift
            if [[ "$#" -eq 0 ]]; then
                err "Missing tool names for --upgrade option"; exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
                case $1 in
                    all)
                        UPGRADE_HOMEBREW=true
                        UPGRADE_PYENV=true
                        UPGRADE_PYTHON=true
                        UPGRADE_PIP=true
                        UPGRADE_VIRTUALENV=true
                        ;;
                    homebrew) UPGRADE_HOMEBREW=true ;;
                    pyenv) UPGRADE_PYENV=true ;;
                    python) UPGRADE_PYTHON=true ;;
                    pip) UPGRADE_PIP=true ;;
                    virtualenv) UPGRADE_VIRTUALENV=true ;;
                    *) err "Unknown package: $1"; exit 1 ;;
                esac
                shift
            done
            continue
            ;;
        --log)
            shift
            if [[ "$#" -eq 0 ]]; then
                err "Missing file path for --log option"; exit 1
            fi
            LOG_FILE="$1"
            shift
            continue
            ;;
        *) err "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Detect if any specific tool was selected for any operation
check_if_any_tool_selected() {
    if [[ "$INSTALL_HOMEBREW" == "true" || "$INSTALL_PYENV" == "true" || "$INSTALL_PYTHON" == "true" || "$INSTALL_PIP" == "true" || "$INSTALL_VIRTUALENV" == "true" || \
           "$REINSTALL_HOMEBREW" == "true" || "$REINSTALL_PYENV" == "true" || "$REINSTALL_PYTHON" == "true" || "$REINSTALL_PIP" == "true" || "$REINSTALL_VIRTUALENV" == "true" || \
           "$REPAIR_HOMEBREW" == "true" || "$REPAIR_PYENV" == "true" || "$REPAIR_PYTHON" == "true" || "$REPAIR_PIP" == "true" || "$REPAIR_VIRTUALENV" == "true" || \
           "$UPGRADE_HOMEBREW" == "true" || "$UPGRADE_PYENV" == "true" || "$UPGRADE_PYTHON" == "true" || "$UPGRADE_PIP" == "true" || "$UPGRADE_VIRTUALENV" == "true" ]]; then
        ANY_TOOL_SELECTED=true
    fi
}

# Check if multiple operation types are specified for the same tool
check_conflicting_operations() {
    local has_conflict=false
    
    # Check for each tool if multiple operations are specified
    for tool in "HOMEBREW" "PYENV" "PYTHON" "PIP" "VIRTUALENV"; do
        local install_var="INSTALL_$tool"
        local reinstall_var="REINSTALL_$tool"
        local repair_var="REPAIR_$tool"
        local upgrade_var="UPGRADE_$tool"
        
        local count=0
        [[ "${!install_var}" == "true" ]] && ((count++))
        [[ "${!reinstall_var}" == "true" ]] && ((count++))
        [[ "${!repair_var}" == "true" ]] && ((count++))
        [[ "${!upgrade_var}" == "true" ]] && ((count++))
        
        if [[ $count -gt 1 ]]; then
            err "Error: Multiple operations specified for $tool: only one of --install, --reinstall, --repair, or --upgrade can be used"
            has_conflict=true
        fi
    done
    
    if [[ "$has_conflict" == "true" ]]; then
        exit 1
    fi
}

# Call the conflict check
check_conflicting_operations

# Set up default log file if not specified by user
if [[ -z "$LOG_FILE" ]]; then
    setup_default_log
fi

# Set up logging
setup_logging "$LOG_FILE"

# Check if multiple options are specified
if [[ ("$REINSTALL_HOMEBREW" == "true" || "$REINSTALL_PYENV" == "true" || "$REINSTALL_PYTHON" == "true" || "$REINSTALL_PIP" == "true" || "$REINSTALL_VIRTUALENV" == "true") && \
      ("$REPAIR_HOMEBREW" == "true" || "$REPAIR_PYENV" == "true" || "$REPAIR_PYTHON" == "true" || "$REPAIR_PIP" == "true" || "$REPAIR_VIRTUALENV" == "true") ]] || \
   [[ ("$REINSTALL_HOMEBREW" == "true" || "$REINSTALL_PYENV" == "true" || "$REINSTALL_PYTHON" == "true" || "$REINSTALL_PIP" == "true" || "$REINSTALL_VIRTUALENV" == "true") && \
      ("$UPGRADE_HOMEBREW" == "true" || "$UPGRADE_PYENV" == "true" || "$UPGRADE_PYTHON" == "true" || "$UPGRADE_PIP" == "true" || "$UPGRADE_VIRTUALENV" == "true") ]] || \
   [[ ("$REPAIR_HOMEBREW" == "true" || "$REPAIR_PYENV" == "true" || "$REPAIR_PYTHON" == "true" || "$REPAIR_PIP" == "true" || "$REPAIR_VIRTUALENV" == "true") && \
      ("$UPGRADE_HOMEBREW" == "true" || "$UPGRADE_PYENV" == "true" || "$UPGRADE_PYTHON" == "true" || "$UPGRADE_PIP" == "true" || "$UPGRADE_VIRTUALENV" == "true") ]]; then
    err "Error: --repair, --install, and --upgrade options cannot be used together"
    exit 1
fi

# Function to display section headers
section() {    
    echo -e "\n${BLUE}===========================================================${RESET}"
    echo -e "${BLUE}$1${RESET}"
    echo -e "${BLUE}===========================================================${RESET}"
}

# Function to check command existence
command_exists() {
    command -v "$1" &> /dev/null
}

# Function for error handling
error_exit() {
    err "$1"
    exit 1
}

# Function to backup file if it exists
backup_file() {
    if [[ -f "$1" ]]; then
        local backup="$1.bak.$(date +%Y%m%d%H%M%S)"
        warn "Backing up $1 to $backup"
        cp "$1" "$backup" || error_exit "Failed to create backup of $1"
    fi
}

# ---------------------- HOMEBREW FUNCTIONS ----------------------

homebrew_uninstall() {
    section "Uninstalling Homebrew"
    if command_exists brew; then
        info "Removing existing Homebrew installation..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)" || error_exit "Failed to uninstall Homebrew"
        success "Homebrew uninstalled successfully"
    else
        warn "Homebrew is not installed"
    fi
}

homebrew_install() {
    section "Installing Homebrew"
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew"
    
    # Add Homebrew to PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || error_exit "Failed to set Homebrew environment"
    
    success "Homebrew installed successfully: $(brew --version | head -1)"
}

homebrew_repair() {
    section "Repairing Homebrew"
    if command_exists brew; then
        info "Updating Homebrew..."
        brew update || error_exit "Failed to update Homebrew"
        info "Running Homebrew doctor..."
        brew doctor || warn "Issues found, but continuing..."
        info "Cleaning up Homebrew..."
        brew cleanup || warn "Cleanup issues, but continuing..."
        success "Homebrew repaired successfully"
    else
        err "Homebrew is not installed. Cannot repair."
        return 1
    fi
}

homebrew_upgrade() {
    section "Upgrading Homebrew"
    if command_exists brew; then
        info "Updating Homebrew formulae..."
        brew update || error_exit "Failed to update Homebrew"
        
        info "Upgrading installed packages..."
        brew upgrade || warn "Some packages could not be upgraded"
        
        info "Cleaning up Homebrew..."
        brew cleanup || warn "Cleanup issues, but continuing..."
        
        success "Homebrew upgraded successfully: $(brew --version | head -1)"
    else
        warn "Homebrew is not installed. Cannot upgrade."
        info "Installing Homebrew instead..."
        homebrew_install
    fi
}

# ---------------------- PYENV FUNCTIONS ----------------------

pyenv_uninstall() {
    section "Uninstalling pyenv"
    if command_exists pyenv; then
        info "Uninstalling pyenv..."
        brew uninstall --force pyenv || error_exit "Failed to uninstall pyenv"
        info "Removing pyenv directory..."
        rm -rf "$HOME/.pyenv" || warn "Could not remove pyenv directory"
        success "pyenv uninstalled successfully"
    else
        warn "pyenv is not installed"
    fi
}

pyenv_install() {
    section "Installing pyenv"
    info "Installing pyenv dependencies..."
    brew install openssl readline sqlite3 xz zlib tcl-tk || error_exit "Failed to install pyenv dependencies"    
    
    info "Installing pyenv..."
    brew install pyenv || error_exit "Failed to install pyenv"
    success "pyenv installed successfully: $(pyenv --version)"

    # Configure shell for pyenv
    configure_pyenv_shell
}

pyenv_repair() {
    section "Repairing pyenv"
    if command_exists pyenv; then
        info "Updating pyenv..."
        brew upgrade pyenv || error_exit "Failed to upgrade pyenv"
        
        info "Reinstalling pyenv dependencies..."
        brew reinstall openssl readline sqlite3 xz zlib tcl-tk || warn "Issues with dependencies, but continuing..."
        
        info "Running pyenv doctor..."
        pyenv doctor 2>/dev/null || warn "pyenv doctor not available, continuing..."
        
        success "pyenv repaired successfully"
    else
        err "pyenv is not installed. Cannot repair."
        return 1
    fi
}

pyenv_upgrade() {
    section "Upgrading pyenv"
    if command_exists pyenv; then
        info "Updating pyenv..."
        brew upgrade pyenv || error_exit "Failed to upgrade pyenv"
        
        info "Updating pyenv dependencies..."
        brew upgrade openssl readline sqlite3 xz zlib tcl-tk || warn "Some dependencies could not be upgraded"
        
        success "pyenv upgraded successfully: $(pyenv --version)"
    else
        warn "pyenv is not installed. Cannot upgrade."
        info "Installing pyenv instead..."
        pyenv_install
    fi
}

# ---------------------- PYTHON FUNCTIONS ----------------------

python_uninstall() {
    section "Uninstalling Python"
    if command_exists pyenv; then
        info "Listing installed Python versions..."
        local versions=$(pyenv versions --bare)
        if [ -z "$versions" ]; then
            warn "No Python versions installed through pyenv"
        else
            info "Uninstalling all Python versions managed by pyenv..."
            for version in $versions; do
                info "Uninstalling Python $version..."
                pyenv uninstall -f "$version" || warn "Failed to uninstall Python $version"
            done
            success "All pyenv Python versions uninstalled successfully"
        fi
    else
        err "pyenv is not installed. Cannot uninstall Python versions."
        return 1
    fi
}

python_install() {
    section "Installing Python"
    if command_exists pyenv; then
        info "Installing latest Python version with pyenv"
        LATEST_PYTHON=$(pyenv install --list | grep -v "[a-zA-Z]" | grep -v - | tail -1 | tr -d '[:space:]')
        pyenv install -s "$LATEST_PYTHON" || error_exit "Failed to install Python $LATEST_PYTHON"
        pyenv global "$LATEST_PYTHON" || error_exit "Failed to set global Python version"
        success "Python $LATEST_PYTHON installed and set as global"
    else
        err "pyenv is not installed. Cannot install Python."
        return 1
    fi
}

python_repair() {
    section "Repairing Python"
    if command_exists pyenv; then
        info "Checking current Python installation..."
        local current_version=$(pyenv global)
        
        if [ -z "$current_version" ] || [ "$current_version" = "system" ]; then
            info "No specific Python version set as global. Installing latest..."
            python_install
        else
            info "Reinstalling current Python version: $current_version..."
            pyenv uninstall -f "$current_version" || warn "Failed to uninstall Python $current_version"
            pyenv install "$current_version" || error_exit "Failed to reinstall Python $current_version"
            pyenv global "$current_version" || error_exit "Failed to set global Python version"
            success "Python $current_version repaired successfully"
        fi
    else
        err "pyenv is not installed. Cannot repair Python."
        return 1
    fi
}

python_upgrade() {
    section "Upgrading Python"
    if command_exists pyenv; then
        info "Checking for newer Python version..."
        local current_version=$(pyenv global)
        local latest_version=$(pyenv install --list | grep -v "[a-zA-Z]" | grep -v - | tail -1 | tr -d '[:space:]')
        
        # Compare version numbers
        if [[ "$current_version" == "$latest_version" ]]; then
            success "Python is already at the latest version: $current_version"
        else
            info "Current Python version: $current_version"
            info "Latest Python version: $latest_version"
            info "Installing latest Python version..."
            
            pyenv install -s "$latest_version" || error_exit "Failed to install Python $latest_version"
            pyenv global "$latest_version" || error_exit "Failed to set global Python version"
            success "Python upgraded from $current_version to $latest_version"
        fi
    else
        warn "pyenv is not installed. Cannot upgrade Python."
        info "Installing pyenv and Python instead..."
        pyenv_install
        python_install
    fi
}

# ---------------------- PIP FUNCTIONS ----------------------

pip_uninstall() {
    section "Uninstalling/Resetting pip"
    if command_exists pip; then
        info "Clearing pip cache..."
        pip cache purge || warn "Failed to purge pip cache"
        
        info "Removing pip configurations..."
        rm -rf "$HOME/.pip" 2>/dev/null || warn "No pip configuration to remove"
        
        success "pip reset successfully"
    else
        err "pip is not installed. Cannot reset."
        return 1
    fi
}

pip_install() {
    section "Installing/Upgrading pip"
    if command_exists python; then
        info "Ensuring pip is installed and up to date..."
        python -m ensurepip || warn "ensurepip not available, trying get-pip.py..."
        
        if ! command_exists pip; then
            info "Installing pip using get-pip.py..."
            curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
            python get-pip.py
            rm -f get-pip.py
        fi
        
        info "Upgrading pip..."
        python -m pip install --upgrade pip || error_exit "Failed to upgrade pip"
        
        success "pip installed/upgraded successfully: $(pip --version)"
    else
        err "Python is not installed. Cannot install pip."
        return 1
    fi
}

pip_repair() {
    section "Repairing pip"
    if command_exists pip; then
        info "Checking pip installation..."
        if ! pip --version >/dev/null 2>&1; then
            info "pip is installed but not functioning correctly. Reinstalling..."
            pip_install
        else
            info "Repairing pip installation..."
            python -m pip uninstall -y pip
            python -m ensurepip || warn "ensurepip not available, trying get-pip.py..."
            python -m pip install --upgrade pip || error_exit "Failed to upgrade pip"
            
            info "Clearing pip cache..."
            pip cache purge || warn "Failed to purge pip cache"
            
            success "pip repaired successfully: $(pip --version)"
        fi
    else
        err "pip is not installed. Cannot repair."
        return 1
    fi
}

pip_upgrade() {
    section "Upgrading pip"
    if command_exists pip; then
        info "Upgrading pip to latest version..."
        python -m pip install --upgrade pip || error_exit "Failed to upgrade pip"
        success "pip upgraded successfully: $(pip --version)"
    else
        warn "pip is not installed. Cannot upgrade."
        info "Installing pip instead..."
        pip_install
    fi
}

# ---------------------- VIRTUALENV FUNCTIONS ----------------------

virtualenv_uninstall() {
    section "Uninstalling virtualenv"
    if command_exists pip; then
        info "Uninstalling virtualenv..."
        pip uninstall -y virtualenv || warn "virtualenv not installed or failed to uninstall"
        success "virtualenv uninstalled successfully"
    else
        err "pip is not installed. Cannot uninstall virtualenv."
        return 1
    fi
}

virtualenv_install() {
    section "Installing virtualenv"
    if command_exists pip; then
        info "Installing virtualenv..."
        pip install virtualenv || error_exit "Failed to install virtualenv"
        success "virtualenv installed successfully: $(virtualenv --version)"
    else
        err "pip is not installed. Cannot install virtualenv."
        return 1
    fi
}

virtualenv_repair() {
    section "Repairing virtualenv"
    if command_exists pip; then
        info "Reinstalling virtualenv..."
        pip uninstall -y virtualenv || warn "virtualenv not installed"
        pip install virtualenv || error_exit "Failed to reinstall virtualenv"
        success "virtualenv repaired successfully: $(virtualenv --version)"
    else
        err "pip is not installed. Cannot repair virtualenv."
        return 1
    fi
}

virtualenv_upgrade() {
    section "Upgrading virtualenv"
    if command_exists pip; then
        info "Upgrading virtualenv to latest version..."
        pip install --upgrade virtualenv || error_exit "Failed to upgrade virtualenv"
        success "virtualenv upgraded successfully: $(virtualenv --version)"
    else
        warn "pip is not installed. Cannot upgrade virtualenv."
        info "Installing pip first..."
        pip_install
        info "Now installing virtualenv..."
        virtualenv_install
    fi
}

# ---------------------- DOTENV FUNCTIONS ----------------------

dotenv_uninstall() {
    section "Uninstalling python-dotenv"
    if command_exists pip; then
        info "Uninstalling python-dotenv..."
        pip uninstall -y python-dotenv || warn "python-dotenv not installed"
        success "python-dotenv uninstalled successfully"
    else
        err "pip is not installed. Cannot uninstall python-dotenv."
        return 1
    fi
}

dotenv_install() {
    section "Installing python-dotenv"
    if command_exists pip; then
        info "Installing python-dotenv..."
        pip install python-dotenv || error_exit "Failed to install python-dotenv"
        success "python-dotenv installed successfully: $(pip show python-dotenv | grep Version)"
    else
        err "pip is not installed. Cannot install python-dotenv."
        return 1
    fi
}

dotenv_repair() {
    section "Repairing python-dotenv"
    if command_exists pip; then
        info "Repairing python-dotenv installation..."
        pip uninstall -y python-dotenv || warn "python-dotenv not installed"
        pip install python-dotenv || error_exit "Failed to install python-dotenv"
        success "python-dotenv repaired successfully: $(pip show python-dotenv | grep Version)"
    else
        err "pip is not installed. Cannot repair python-dotenv."
        return 1
    fi
}

# ---------------------- SHELL CONFIGURATION ----------------------

configure_pyenv_shell() {
    section "Configuring Shell Environment for pyenv"

    # Determine shell configuration file
    SHELL_NAME=$(basename "$SHELL")
    if [[ "$SHELL_NAME" == "zsh" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$SHELL_NAME" == "bash" ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
        # On macOS, also check bash_profile
        [[ -f "$HOME/.bash_profile" ]] && SHELL_CONFIG="$HOME/.bash_profile"
    else
        error_exit "Unsupported shell: $SHELL_NAME. Please use bash or zsh."
    fi

    info "Using shell config file: $SHELL_CONFIG"
    backup_file "$SHELL_CONFIG"

    # Check if pyenv init is already in shell config
    if grep -q "pyenv init" "$SHELL_CONFIG" && [[ "$REINSTALL_ALL" == "false" ]] && [[ "$REINSTALL_PYENV" == "false" ]]; then
        success "pyenv initialization already configured in $SHELL_CONFIG"
    else
        info "Adding pyenv initialization to $SHELL_CONFIG..."
        
        # Check if we need to add pyenv configuration
        if [[ "$REINSTALL_ALL" == "true" ]] || [[ "$REINSTALL_PYENV" == "true" ]]; then
            # Remove existing pyenv config lines if force is enabled
            sed -i.bak '/export PYENV_ROOT/d' "$SHELL_CONFIG"
            sed -i.bak '/pyenv init/d' "$SHELL_CONFIG"
        fi
        
        # Add pyenv configuration to shell config
        cat >> "$SHELL_CONFIG" << 'EOT'

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOT
        success "pyenv initialization added to $SHELL_CONFIG"
    fi
}


# Function to handle Homebrew installation, repair, and upgrade
handle_homebrew() {
    if [[ "$REINSTALL_HOMEBREW" == "true" ]]; then
        homebrew_uninstall
        homebrew_install
    elif [[ "$INSTALL_HOMEBREW" == "true" ]]; then
        homebrew_install
    elif [[ "$REPAIR_HOMEBREW" == "true" ]]; then
        homebrew_repair
    elif [[ "$UPGRADE_HOMEBREW" == "true" ]]; then
        homebrew_upgrade
    elif command_exists brew; then
        homebrew_repair
    else
        homebrew_install
    fi
}

# Function to handle pyenv operations
handle_pyenv() {
    if [[ "$REINSTALL_PYENV" == "true" ]]; then
        pyenv_uninstall
        pyenv_install
    elif [[ "$INSTALL_PYENV" == "true" ]]; then
        pyenv_install
    elif [[ "$REPAIR_PYENV" == "true" ]]; then
        pyenv_repair
    elif [[ "$UPGRADE_PYENV" == "true" ]]; then
        pyenv_upgrade
    elif command_exists pyenv; then
        pyenv_repair
    else
        pyenv_install
    fi
}

# Function to handle Python operations
handle_python() {
    if [[ "$REINSTALL_PYTHON" == "true" ]]; then
        python_uninstall
        python_install
    elif [[ "$INSTALL_PYTHON" == "true" ]]; then
        python_install
    elif [[ "$REPAIR_PYTHON" == "true" ]]; then
        python_repair
    elif [[ "$UPGRADE_PYTHON" == "true" ]]; then
        python_upgrade
    elif command_exists python; then
        # Check if Python is managed by pyenv
        if [[ "$(which python)" == *".pyenv"* ]]; then
            success "Python already installed and managed by pyenv: $(python --version)"
        else
            python_install
        fi
    else
        python_install
    fi
}

# Function to handle pip operations
handle_pip() {
    if [[ "$REINSTALL_PIP" == "true" ]]; then
        pip_uninstall
        pip_install
    elif [[ "$INSTALL_PIP" == "true" ]]; then
        pip_install
    elif [[ "$REPAIR_PIP" == "true" ]]; then
        pip_repair
    elif [[ "$UPGRADE_PIP" == "true" ]]; then
        pip_upgrade
    elif command_exists pip; then
        pip_repair
    else
        pip_install
    fi
}

# Function to handle virtualenv operations
handle_virtualenv() {
    if [[ "$REINSTALL_VIRTUALENV" == "true" ]]; then
        virtualenv_uninstall
        virtualenv_install
    elif [[ "$INSTALL_VIRTUALENV" == "true" ]]; then
        virtualenv_install
    elif [[ "$REPAIR_VIRTUALENV" == "true" ]]; then
        virtualenv_repair
    elif [[ "$UPGRADE_VIRTUALENV" == "true" ]]; then
        virtualenv_upgrade
    elif command_exists virtualenv; then
        info "virtualenv is already installed: $(virtualenv --version)"
    else
        virtualenv_install
    fi
}

# Check if any specific tool was selected
check_if_any_tool_selected

# Process only the selected tools, or all if none were specifically selected
if [[ "$ANY_TOOL_SELECTED" == "true" ]]; then
    # Process only the selected tools
    info "Processing only the selected tools..."
    
    # Process Homebrew if selected
    if [[ "$INSTALL_HOMEBREW" == "true" || "$REINSTALL_HOMEBREW" == "true" || "$REPAIR_HOMEBREW" == "true" || "$UPGRADE_HOMEBREW" == "true" ]]; then
        handle_homebrew
    fi
    
    # Process pyenv if selected
    if [[ "$INSTALL_PYENV" == "true" || "$REINSTALL_PYENV" == "true" || "$REPAIR_PYENV" == "true" || "$UPGRADE_PYENV" == "true" ]]; then
        handle_pyenv
    fi
    
    # Process Python if selected
    if [[ "$INSTALL_PYTHON" == "true" || "$REINSTALL_PYTHON" == "true" || "$REPAIR_PYTHON" == "true" || "$UPGRADE_PYTHON" == "true" ]]; then
        handle_python
    fi
    
    # Process pip if selected
    if [[ "$INSTALL_PIP" == "true" || "$REINSTALL_PIP" == "true" || "$REPAIR_PIP" == "true" || "$UPGRADE_PIP" == "true" ]]; then
        handle_pip
    fi
    
    # Process virtualenv if selected
    if [[ "$INSTALL_VIRTUALENV" == "true" || "$REINSTALL_VIRTUALENV" == "true" || "$REPAIR_VIRTUALENV" == "true" || "$UPGRADE_VIRTUALENV" == "true" ]]; then
        handle_virtualenv
    fi

    # Only install dotenv if pip was selected (dotenv depends on pip)
    if [[ "$INSTALL_PIP" == "true" || "$REINSTALL_PIP" == "true" || "$REPAIR_PIP" == "true" || "$UPGRADE_PIP" == "true" ]]; then
        dotenv_install
    fi
else
    # No specific tool was selected, process all tools
    info "No specific tool selected, processing all tools..."
    handle_homebrew
    handle_pyenv
    handle_python
    handle_pip
    handle_virtualenv
    dotenv_install
fi

# Final summary
section "Installation Summary"

# Only show summary for tools that were processed
if [[ "$ANY_TOOL_SELECTED" == "true" ]]; then
    if [[ "$INSTALL_HOMEBREW" == "true" || "$REINSTALL_HOMEBREW" == "true" || "$REPAIR_HOMEBREW" == "true" || "$UPGRADE_HOMEBREW" == "true" ]]; then
        if command_exists brew; then
            success "✓ Homebrew: $(brew --version | head -1)"
        else
            warn "✗ Homebrew: Not installed"
        fi
    fi
    
    if [[ "$INSTALL_PYENV" == "true" || "$REINSTALL_PYENV" == "true" || "$REPAIR_PYENV" == "true" || "$UPGRADE_PYENV" == "true" ]]; then
        if command_exists pyenv; then
            success "✓ pyenv: $(pyenv --version)"
        else
            warn "✗ pyenv: Not installed"
        fi
    fi
    
    if [[ "$INSTALL_PYTHON" == "true" || "$REINSTALL_PYTHON" == "true" || "$REPAIR_PYTHON" == "true" || "$UPGRADE_PYTHON" == "true" ]]; then
        if command_exists python; then
            success "✓ Python: $(python --version)"
        else
            warn "✗ Python: Not installed"
        fi
    fi
    
    if [[ "$INSTALL_PIP" == "true" || "$REINSTALL_PIP" == "true" || "$REPAIR_PIP" == "true" || "$UPGRADE_PIP" == "true" ]]; then
        if command_exists pip; then
            success "✓ pip: $(pip --version)"
        else
            warn "✗ pip: Not installed"
        fi
        
        if command_exists pip && command_exists python; then
            success "✓ python-dotenv: $(pip show python-dotenv | grep Version 2>/dev/null || echo "Not installed")"
        fi
    fi
    
    if [[ "$INSTALL_VIRTUALENV" == "true" || "$REINSTALL_VIRTUALENV" == "true" || "$REPAIR_VIRTUALENV" == "true" || "$UPGRADE_VIRTUALENV" == "true" ]]; then
        if command_exists virtualenv; then
            success "✓ virtualenv: $(virtualenv --version)"
        else
            warn "✗ virtualenv: Not installed"
        fi
    fi
else
    # Show summary for all tools
    if command_exists brew; then
        success "✓ Homebrew: $(brew --version | head -1)"
    else
        warn "✗ Homebrew: Not installed"
    fi
    
    if command_exists pyenv; then
        success "✓ pyenv: $(pyenv --version)"
    else
        warn "✗ pyenv: Not installed"
    fi
    
    if command_exists python; then
        success "✓ Python: $(python --version)"
    else
        warn "✗ Python: Not installed"
    fi
    
    if command_exists pip; then
        success "✓ pip: $(pip --version)"
    else
        warn "✗ pip: Not installed"
    fi
    
    if command_exists virtualenv; then
        success "✓ virtualenv: $(virtualenv --version)"
    else
        warn "✗ virtualenv: Not installed"
    fi
    
    if command_exists pip && command_exists python; then
        success "✓ python-dotenv: $(pip show python-dotenv | grep Version 2>/dev/null || echo "Not installed")"
    fi
fi

info "\nNext Steps:"
info "1. Restart your terminal or run: source $SHELL_CONFIG"
info "2. Verify installation with: pyenv --version"
info "3. Install specific Python version with: pyenv install 3.x.x"
info "4. Create project environments with: pyenv local 3.x.x"

# Add a note about the log file at the end
if [[ "$LOGGING_ENABLED" == "true" ]]; then
    echo "===============================================" >> "$LOG_FILE"
    echo "Log completed at: $(date)" >> "$LOG_FILE"
    echo "===============================================" >> "$LOG_FILE"
    
    success "\nA complete log of this installation has been saved to: $LOG_FILE"
fi

success "\nPython development environment setup completed successfully!"
exit 0