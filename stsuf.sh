#!/bin/bash

usage() {
    echo "Usage: $0 <directory>"
    echo "  directory : path to directory (required)"
    echo ""
    echo "Example: $0 /home/user/documents"
    exit 1
}

get_suffix() {
    local filename="$1"
    
    if [[ "$filename" == .* ]]; then
        local temp="${filename#.}"
        
        if [ -z "$temp" ]; then
            echo "no suffix"
            return
        fi
        
        if [[ "$temp" == *.* ]]; then
            echo ".${temp##*.}"
            return
        else
            echo "no suffix"
            return
        fi
    fi
    
    if [[ "$filename" == *.* ]]; then
        echo ".${filename##*.}"
    else
        echo "no suffix"
    fi
}

if [ $# -ne 1 ]; then
    echo "Error: Expected 1 argument, got $#"
    usage
fi

directory="$1"

if [ ! -d "$directory" ]; then
    echo "Error: '$directory' is not a directory or does not exist"
    exit 1
fi

declare -A suffix_count

echo "Analyzing files in '$directory'..."
echo ""

while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")
    
    suffix=$(get_suffix "$filename")
    
    if [ -n "${suffix_count[$suffix]}" ]; then
        ((suffix_count[$suffix]++))
    else
        suffix_count[$suffix]=1
    fi
done < <(find "$directory" -type f -print0)

if [ ${#suffix_count[@]} -eq 0 ]; then
    echo "No files found in '$directory'"
    exit 0
fi

echo "File suffix statistics:"
echo ""

for suffix in "${!suffix_count[@]}"; do
    echo "${suffix_count[$suffix]} $suffix"
done | sort -rn | while read count suffix; do
    printf "%s: %d\n" "$suffix" "$count"
done
