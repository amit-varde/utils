#!/bin/bash
#---------------------------------------------------------------------------------------------------
# This is for temp code of quick bash functions
#---------------------------------------------------------------------------------------------------
tkdiff_remote() {
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

  tkdiff "$file" <(git show "origin/$branch:$file")
}

# Example usage: 
tkdiff_remote ./alias