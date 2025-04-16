#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Header: Utility script for running Python scripts, pytest, and shell commands.
# It sets up a global output_file based on the VSCode workspace and provides
# functions for traversing directories and executing commands.
# -----------------------------------------------------------------------------
[[ -z "${BASH_UTILS_LOADED}" ]] && { echo "ERROR: util_bash.sh is not loaded. Please source it before using this script."; exit 1; }
traverse_up() { # Function to traverse upward looking for specific pattern
    local pattern="$1"
    local dir="${2:-.}"
    local stop="${3:-/}"
    while [ "$dir" != "$stop" ] && [ "$dir" != "/" ]; do
        if ls "$dir"/$pattern >/dev/null 2>&1; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    if [ -d "$stop" ] && ls "$stop"/$pattern >/dev/null 2>&1; then
        echo "$stop"
        return 0
    fi
    return 1
}
# Global output_file setting using traverse_up for *.code-workspace file
found=$(traverse_up "*.code-workspace" "$(pwd)" "/")
if [ -n "$found" ]; then
    output_file="${found}/run.out"
else
    output_file="/tmp/${USER}.run.out"
fi
# -----------------------------------------------------------------------------
run() { # Run a Python script with arguments and save output to run.out
    clear
    local script="$1"
    # Removed local output_file assignment, using global 'output_file'
    shift
    [ -z "$script" ] && { echo -e "${RED}Error: No Python script specified.${RESET}"; return 1; }
    [ ! -f "$script" ] && { echo -e "${RED}Error: Python script '$script' does not exist.${RESET}"; return 1; }
    echo -e "${BLUE}Running Python script '$script' with arguments: $*${RESET}"
    python "$script" "$@" | tee "$output_file"
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Script executed successfully. Output saved to '$output_file'.${RESET}"
    else
        echo -e "${RED}Failure: Some tests failed. Check '$output_file' for details.${RESET}"
    fi
}
# -----------------------------------------------------------------------------
run_pytest() { # Run pytest on specified test files and save output to pytest.out
    clear
    local test_path="$1"
    local output_file="pytest.out"
    shift

    if [ -z "$test_path" ]; then
        echo -e "${BLUE}Running pytest on current directory with arguments: $*${RESET}"
        pytest "$@" -v 2>&1 | tee "$output_file"
    elif [ -f "$test_path" ] || [ -d "$test_path" ]; then
        echo -e "${BLUE}Running pytest on '$test_path' with arguments: $*${RESET}"
        pytest "$test_path" "$@" -v 2>&1 | tee "$output_file"
    else
        echo -e "${RED}Error: Test path '$test_path' does not exist.${RESET}"
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Tests executed successfully. Output saved to '$output_file'.${RESET}"
    else
        echo -e "${RED}Failure: Some tests failed. Check '$output_file' for details.${RESET}"
    fi
}
# -----------------------------------------------------------------------------
run_py() { # Run Python script and save output to run.out
    clear
    local script_path="$1"
    # Removed local output_file assignment, using global 'output_file'
    shift

    if [ -z "$script_path" ]; then
        echo -e "${RED}Error: No Python script specified.${RESET}"
        return 1
    elif [ -f "$script_path" ]; then
        echo -e "${BLUE}Running Python script '$script_path' with arguments: $*${RESET}"
        python "$script_path" "$@" 2>&1 | tee "$output_file"
    else
        echo -e "${RED}Error: Python script '$script_path' does not exist.${RESET}"
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Python script executed successfully. Output saved to '$output_file'.${RESET}"
    else
        echo -e "${RED}Failure: Script failed. Check '$output_file' for details.${RESET}"
    fi
}
# -----------------------------------------------------------------------------
run_cmd() { # Run any shell command and save output to cmd.out
    clear
    local cmd="$1"
    local output_file="cmd.out"
    shift
    [ -z "$cmd" ] && { echo -e "${RED}Error: No command specified.${RESET}"; return 1; }
    echo -e "${BLUE}Running command: $cmd $*${RESET}"
    $cmd "$@" 2>&1 | tee "$output_file"
    local exit_status=${PIPESTATUS[0]}
    if [ $exit_status -eq 0 ]; then
        echo -e "${GREEN}Success: Command executed successfully. Output saved to '$output_file'.${RESET}"
    else
        echo -e "${RED}Failure: Command failed with exit code $exit_status. Check '$output_file' for details.${RESET}"
    fi
    return $exit_status
}
# -----------------------------------------------------------------------------
list_bash_functions_in_file >/dev/null 2>&1 && list_bash_functions_in_file "$(realpath "$0")" || echo -e "${RED}alias is not loaded${RESET}"
