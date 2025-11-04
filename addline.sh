#!/bin/bash

usage() {
    echo "Usage: $0 <directory>"
    echo "  directory : path to directory (required)"
    echo ""
    echo "Example: $0 /home/user/documents"
    exit 1
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

username="$USER"

current_date=$(date -I)

approval_line="Approved $username $current_date"

echo "Processing .txt files in '$directory'..."
echo "Approval line: $approval_line"
echo ""

processed_count=0

for filepath in "$directory"/*.txt; do
    if [ ! -e "$filepath" ]; then
        echo "No .txt files found in '$directory'"
        break
    fi
    
    if [ ! -f "$filepath" ]; then
        continue
    fi
    
    filename=$(basename "$filepath")
    
    temp_file=$(mktemp)
    
    echo "$approval_line" > "$temp_file"
    
    cat "$filepath" >> "$temp_file"
    
    mv "$temp_file" "$filepath"
    
    if [ $? -eq 0 ]; then
        echo "Processed: $filename"
        ((processed_count++))
    else
        echo "Error: Failed to process '$filename'"
        rm -f "$temp_file"
    fi
done

echo ""
echo "Total files processed: $processed_count"
