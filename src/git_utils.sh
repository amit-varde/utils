#!/bin/bash
# -----------------------------------------------------------------------------
# Git alias and functions documentation header
#
# Functions available:
#   git_file_info()    - Displays version info for a file.
#   git_file_history() - Shows commit history for a file.
#   git_restore()      - Restores file(s)/directory to the HEAD version.
#   git_audit_trail()  - Checks for a GitHub repository for audit actions.
#   discard_changes()  - Discards local changes replacing the file with HEAD.
#   git_stash_named()  - Creates a new git stash with the provided name/message.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Function: is_git_repo
# Description: Checks if the current directory is within a git repository.
# Returns: 0 (success) if in a git repo, 1 (failure) otherwise.
# -----------------------------------------------------------------------------
is_git_repo() {
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
# Function: git_file_info
# Description: Displays version information for a given file based on git history.
# Parameters:
#   $1 - Path to the file.
# -----------------------------------------------------------------------------
git_file_info() {
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
# Function: git_file_history
# Description: Outputs the git commit history for the specified file, following renames.
# Parameters:
#   $1 - Path to the file.
# -----------------------------------------------------------------------------
git_file_history() {
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
# Function: git_restore
# Description: Restores the specified file(s) or directory to the version at HEAD.
# Parameters:
#   $@ - One or more files or directories.
# -----------------------------------------------------------------------------
git_restore() { 
    [ "$#" -eq 0 ] && { echo "Usage: git_restore <file_or_directory> [additional targets...]"; return 1; }
    is_git_repo || return 1
    for target in "$@"; do 
        echo "Restoring '$target' to HEAD..."; 
        git help restore >/dev/null 2>&1 && git restore "$target" || git checkout HEAD -- "$target"; 
    done
}

# -----------------------------------------------------------------------------
# Function: git_audit_trail
# Description: Checks if the current directory is a git repository and contained in a GitHub
#              remote; intended for audit trail actions.
# -----------------------------------------------------------------------------
git_audit_trail() {
    is_git_repo || return 1
    # Check if remote origin URL contains github.com
    remote=$(git config --get remote.origin.url)
    [[ ! $remote =~ github.com ]] && { echo "Not a GitHub repository"; return 1; }
    # (Additional functionality can be added here)
}

# -----------------------------------------------------------------------------
# Function: discard_changes
# Description: Discards local modifications to a specified file and replaces it with the version from HEAD.
# Parameters:
#   $1 - The file whose changes are to be discarded.
# -----------------------------------------------------------------------------
discard_changes() {
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
# Function: git_stash_named
# Description: Creates a new git stash with the provided name/message.
# Parameters:
#   $1 - The name/message for the stash.
# -----------------------------------------------------------------------------
git_stash_named() {
    is_git_repo || return 1
    # Validate input parameter
    [ -z "$1" ] && { echo "Usage: git_stash_named <stash_name>"; return 1; }
    
    # Create a git stash with the provided name
    git stash push -m "$1"
}

# -----------------------------------------------------------------------------
# Function: git_stash_list
# Description: Lists all git stashes in the repository.
# -----------------------------------------------------------------------------
git_stash_list() {
    is_git_repo || return 1
    git stash list
}