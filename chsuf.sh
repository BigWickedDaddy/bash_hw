#!/bin/bash

usage() {
    echo "Usage: $0 <directory> <old_suffix> <new_suffix>"
    echo "  directory    : path to directory (required)"
    echo "  old_suffix   : old file suffix starting with . (required)"
    echo "  new_suffix   : new file suffix starting with . (required)"
    echo ""
    echo "Example: $0 /path/to/dir .txt .md"
    exit 1
}

validate_suffix() {
    local suffix="$1"
    
    if [[ ! "$suffix" =~ ^\. ]]; then
        return 1
    fi
    
    if [ "$suffix" = "." ]; then
        return 1
    fi
    
    local after_dot="${suffix:1}"
    if [[ "$after_dot" =~ \. ]]; then
        return 1
    fi
    
    return 0
}

if [ $# -ne 3 ]; then
    echo "Error: Expected 3 arguments, got $#"
    usage
fi

directory="$1"
old_suffix="$2"
new_suffix="$3"

if [ ! -d "$directory" ]; then
    echo "Error: '$directory' is not a directory or does not exist"
    exit 1
fi

if ! validate_suffix "$old_suffix"; then
    echo "Error: Invalid old suffix '$old_suffix'"
    echo "Suffix must start with '.' and contain no additional '.' characters"
    exit 1
fi

if ! validate_suffix "$new_suffix"; then
    echo "Error: Invalid new suffix '$new_suffix'"
    echo "Suffix must start with '.' and contain no additional '.' characters"
    exit 1
fi

renamed_count=0

echo "Searching for files with suffix '$old_suffix' in '$directory'..."
echo ""

while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")
    dirpath=$(dirname "$filepath")
    
    if [[ "$filename" == *"$old_suffix" ]]; then
        if [[ "$filename" == .* ]] && [[ ! "$filename" =~ ^\..+$ ]] || [[ "$filename" == "$old_suffix" ]]; then
            continue
        fi
     
        basename_no_suffix="${filename%$old_suffix}"
        
        if [ -z "$basename_no_suffix" ] || [ "$basename_no_suffix" = "." ]; then
            continue
        fi
        
        new_filename="${basename_no_suffix}${new_suffix}"
        new_filepath="$dirpath/$new_filename"
        
        if [ -e "$new_filepath" ]; then
            echo "Warning: Cannot rename '$filepath' - '$new_filepath' already exists"
            continue
        fi
        
        mv "$filepath" "$new_filepath"
        
        if [ $? -eq 0 ]; then
            echo "Renamed: $filepath -> $new_filepath"
            ((renamed_count++))
        else
            echo "Error: Failed to rename '$filepath'"
        fi
    fi
done < <(find "$directory" -type f -print0)

echo ""
echo "Total files renamed: $renamed_count"
