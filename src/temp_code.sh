rename_files_to_lowercase() {
    local dir="${1:-.}"  # Default to current directory if not provided
    
    # Check if directory exists
    if [ ! -d "$dir" ]; then
        echo "Error: Directory '$dir' does not exist."
        return 1
    fi
    
    # Change to the directory
    pushd "$dir" > /dev/null || return 1
    
    # Loop over every file in the current directory
    for file in *; do
        # Only process regular files
        if [ -f "$file" ]; then
            # Extract extension if it exists
            ext=""
            if [[ "$file" == *.* ]]; then
                ext=".${file##*.}"
                base="${file%.*}"
            else
                base="$file"
            fi
            
            # Convert filename to lowercase
            lower=$(echo "$base" | tr '[:upper:]' '[:lower:]')
            # Replace any character not a-z or 0-9 with an underscore
            newbase=$(echo "$lower" | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//')
            # Convert extension to lowercase too
            lowercase_ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            # Combine processed base and extension
            newname="${newbase}${lowercase_ext}"
            
            # Rename if the new name differs from the original
            if [ "$file" != "$newname" ]; then
                if [ -e "$newname" ]; then
                    echo "Skipping '$file' because target '$newname' already exists."
                else
                    echo "Renaming '$file' to '$newname'"
                    mv "$file" "$newname"
                fi
            fi
        fi
    done
    
    # Return to original directory
    popd > /dev/null
}
rename_files_to_lowercase /Users/amit/Downloads/notes