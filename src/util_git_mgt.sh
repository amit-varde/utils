#!/bin/bash
# -----------------------------------------------------------------------------
# File: git_utils.sh
# Author: Amit Varde
# Email: tercel04@gmail.com; tercel04@gmail.com
# -----------------------------------------------------------------------------
# DESCRIPTIONS:
# A collection of utility functions for working with Git repositories.
# This script provides helper functions for common Git operations,
# file tracking, history management, and repository information.
# -----------------------------------------------------------------------------
# USAGE:
# Source this file in your shell configuration or other scripts:
# source /path/to/git_utils.sh
# This loads the git functions that can be used on the terminals


# -----------------------------------------------------------------------------
tkdiff_remote() { # Compares a local file to its counterpart on the remote origin for the current branch.
  if [ -z "$1" ]; then
    echo "Usage: tkdiff_remote <file>"
    return 1
  fi

  local file="$1"
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  
  # Get and display remote repository information
  local remote_url
  remote_url=$(git config --get remote.origin.url)
  if [ -z "$remote_url" ]; then
    echo "Error: No remote 'origin' configured."
    return 1
  fi
  
  echo "Remote repository: $remote_url"
  echo "Current branch: $branch"
  echo "Comparing local '$file' with remote 'origin/$branch:$file'"

  if ! git ls-remote --exit-code origin &>/dev/null; then
    echo "Remote 'origin' not found or not accessible."
    return 1
  fi

  # Check if the branch exists on the remote
  if ! git ls-remote --heads origin "$branch" | grep -q "$branch"; then
    echo "Branch '$branch' does not exist on remote 'origin'."
    return 1
  fi

  if ! git ls-tree -r "origin/$branch" --name-only | grep -q "^$file$"; then
    echo "File '$file' not found in origin/$branch."
    return 1
  fi

command -v tkdiff >/dev/null 2>&1 \
       && tkdiff "$file" <(git show "origin/$branch:$file") 
       || { echo "Error: tkdiff is not installed. Please install tkdiff to use this function."; return 1; }
}

# -----------------------------------------------------------------------------
is_git_repo() {   # Checks if the current directory is within a git repository
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    # It's a git repo, check if it's GitHub
    remote=$(git config --get remote.origin.url 2>/dev/null)
    if [[ $remote =~ github.com[:/]([^/]+/[^/.]+) ]]; then
        # It's a GitHub repo, extract the repository name
        echo "${BASH_REMATCH[1]}"
        return 2
    else
        # It's a local-only repo, extract repo name from directory
        repo_name=$(basename "$(git rev-parse --show-toplevel)")
        echo "local_${repo_name}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
git_file_info() {   # Displays version information for a given file based on git history
    local file="$1"
    [ -z "$file" ] && { echo "Error: No file specified."; return 1; }
    [ ! -f "$file" ] && { echo "Error: File '$file' does not exist."; return 1; }
    echo "File Version Info: $file"
    echo "Version: $(git log -n 1 --pretty=format:"%h" -- "$file")"
    echo "Last Updated: $(git log -n 1 --pretty=format:"%ad" --date=short -- "$file")"
    echo "Last Update Message: $(git log -n 1 --pretty=format:"%s" -- "$file")"
    local git_sha=$(git log -n 1 --pretty=format:"%h" -- "$file")
    local local_sha=$(shasum -a 256 "$file" | awk '{print $1}')
    local git_file_content=$(git show "$git_sha:$file" 2>/dev/null | shasum -a 256 | awk '{print $1}')
    echo "Tags: $(git tag --contains $git_sha | tr '\n' ' ')"
    echo "SHA (Git): $git_file_content"
        if [ "$local_sha" != "$git_file_content" ]; then
            echo "Status: MODIFIED"
            echo "SHA (Local): $local_sha (modified)"
        else
            echo "Status: UNCHANGED"
            echo "SHA (Local): $local_sha"
        fi
}

# -----------------------------------------------------------------------------
git_file_history() {   # Outputs the git commit history for the specified file, following renames
    local file="$1"
    [ -z "$file" ] && { echo "Error: No file specified."; return 1; }
    [ ! -f "$file" ] && { echo "Error: File '$file' does not exist."; return 1; }
    echo "Git history for file: $file"
    # Get total number of commits for this file
    local total=$(git log --follow --oneline -- "$file" | wc -l | tr -d ' ')
    # Show history with version numbering
    git log --reverse --follow --pretty=format:"%C(green)%D%C(reset)/v%H,%C(yellow)%h%C(reset),%ad,%s" --date=format:"%Y-%m-%d %H:%M:%S" -- "$file" | 
    awk -v total="$total" '{
        # Extract branch info
        branch = "";
        if ($0 ~ /,/) {
            split($0, parts, ",");
            if (parts[1] ~ /HEAD -> /) {
                gsub(".*HEAD -> ", "", parts[1]);
                branch = parts[1];
            } else if (parts[1] ~ /tag: /) {
                gsub(".*tag: ", "", parts[1]);
                branch = parts[1];
            }
            if (branch == "") branch = "main";
        }
        # Replace version hash with version number
        gsub("v[0-9a-f]+", "v" NR, $0);
        # Print with branch prefix for version number
        if (branch != "") {
            sub("v" NR, branch "/v" NR, $0);
        }
        print $0;
    }' > /tmp/git-file-history.csv
    # Open the CSV file with VS Code
    code /tmp/git-file-history.csv
}

# -----------------------------------------------------------------------------
git_restore() {   # Restores the specified file(s) or directory to the version at HEAD
    [ "$#" -eq 0 ] && { echo "Usage: git_restore <file_or_directory> [additional targets...]"; return 1; }
    is_git_repo || return 1
    for target in "$@"; do 
        echo "Restoring '$target' to HEAD..."; 
        git help restore >/dev/null 2>&1 && git restore "$target" || git checkout HEAD -- "$target"; 
    done
}

# -----------------------------------------------------------------------------
git_audit_trail() {   # Checks if the current directory is a git repository contained in a GitHub remote
    is_git_repo || return 1
    # Check if remote origin URL contains github.com
    remote=$(git config --get remote.origin.url)
    [[ ! $remote =~ github.com ]] && { echo "Not a GitHub repository"; return 1; }
    # (Additional functionality can be added here)
}

# -----------------------------------------------------------------------------
discard_changes() {   # Discards local modifications to a specified file
    is_git_repo || return 1
    remote=$(git config --get remote.origin.url)
    [[ ! $remote =~ github.com ]] && { echo "Not a GitHub repository"; return 1; }
    # Validate input parameter
    [ -z "$1" ] && { echo "Usage: discard_changes <file>"; return 1; }
    [ ! -f "$1" ] && { echo "File not found: $1"; return 1; }
    # Discard local changes and replace the file with version from HEAD
    git checkout HEAD -- "$1"
    echo "Discarded changes to $1. File replaced with HEAD version."
}

# -----------------------------------------------------------------------------
git_stash_named() {   # Creates a new git stash with the provided name/message
    is_git_repo || return 1
    # Validate input parameter
    [ -z "$1" ] && { echo "Usage: git_stash_named <stash_name>"; return 1; }
    # Create a git stash with the provided name
    git stash push -m "$1"
}

# -----------------------------------------------------------------------------
git_stash_list() {   # Lists all git stashes in the repository
    is_git_repo || return 1
    git stash list
}

# -----------------------------------------------------------------------------
# If loading is successful this will be executed
# Always makes sure this is the last function call
type list_bash_functions_in_file >/dev/null 2>&1 && list_bash_functions_in_file "$(realpath "$0")" || echo "Error: alias is not loaded"
# -----------------------------------------------------------------------------