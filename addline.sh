#!/bin/bash


usage() {
    echo "Usage:"
    echo "  $0 <directory>"
    echo "  $0 --dir <directory>"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/dir"
    echo "  $0 --dir /path/to/dir"
    exit 1
}
directory=""
if [[ $# -eq 1 && "$1" != --* ]]; then
    directory="$1"
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir) directory="$2"; shift 2 ;;
            -h|--help) usage ;;
            *) echo "Error: unknown option $1"; usage ;;
        esac
    done
fi

if [[ -z "$directory" ]]; then
    echo "Error: directory is required"
    usage
fi
if [[ ! -d "$directory" ]]; then
    echo "Error: '$directory' is not a directory or does not exist"
    exit 1
fi

username="${USER:-$(id -un 2>/dev/null)}"

if date -I >/dev/null 2>&1; then
    current_date="$(date -I)"
else
    current_date="$(date '+%Y-%m-%d')"
fi

approval_line="Approved $username $current_date"

echo "Processing .txt files in '$directory'..."
echo "Approval line: $approval_line"
echo ""

processed_count=0
found_any=0

shopt -s nullglob

for filepath in "$directory"/*.txt; do
    found_any=1

    [[ -f "$filepath" ]] || continue

    filename=$(basename "$filepath")

    temp_file="${filepath}.addline.tmp.$$"

    {
        printf "%s\n" "$approval_line"
        cat "$filepath"
    } > "$temp_file" || {
        echo "Error: failed to write temp file for '$filename'"
        continue
    }

    if mv -- "$temp_file" "$filepath"; then
        echo "Processed: $filename"
        ((processed_count++))
    else
        echo "Error: failed to replace '$filename' with temp file"
    fi
done

shopt -u nullglob

if [[ $found_any -eq 0 ]]; then
    echo "No .txt files found in '$directory'"
fi

echo ""
echo "Total files processed: $processed_count"
