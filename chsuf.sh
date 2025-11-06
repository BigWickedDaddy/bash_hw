#!/bin/bash

usage() {
    echo "Usage:"
    echo "  $0 <directory> <old_suffix> <new_suffix>"
    echo "  $0 --dir <directory> --old <old_suffix> --new <new_suffix>"
    echo ""
    echo "Rules for suffix:"
    echo "  - starts with '.'"
    echo "  - not equal to '.'"
    echo "  - no additional '.' after the first dot"
    echo "Examples:"
    echo "  $0 /path/to/dir .txt .md"
    echo "  $0 --dir /path/to/dir --old .txt --new .md"
    exit 1
}

validate_suffix() {
    local s="$1"
    [[ "$s" == .* ]] || return 1
    [[ "$s" != "." ]] || return 1
    local tail="${s:1}"
    [[ "$tail" != *.* ]] || return 1
    return 0
}

dir=""
old=""
new=""

if [[ $# -eq 3 ]]; then
    dir="$1"
    old="$2"
    new="$3"
else
    # разбор именованных
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)  dir="$2"; shift 2 ;;
            --old)  old="$2"; shift 2 ;;
            --new)  new="$2"; shift 2 ;;
            -h|--help) usage ;;
            *) echo "Error: unknown option or wrong arity: $1"; usage ;;
        esac
    done
fi

if [[ -z "$dir" || -z "$old" || -z "$new" ]]; then
    echo "Error: directory, old_suffix and new_suffix are required"
    usage
fi

if [[ ! -d "$dir" ]]; then
    echo "Error: '$dir' is not a directory or does not exist"
    exit 1
fi

if ! validate_suffix "$old"; then
    echo "Error: invalid old suffix '$old'"
    echo "Suffix must start with '.', not be '.', and contain no extra '.'"
    exit 1
fi
if ! validate_suffix "$new"; then
    echo "Error: invalid new suffix '$new'"
    echo "Suffix must start with '.', not be '.', and contain no extra '.'"
    exit 1
fi

renamed_count=0
echo "Searching for files with suffix '$old' in '$dir'..."
echo ""

while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")
    dirpath=$(dirname "$filepath")

    if [[ "$filename" == *"$old" ]]; then
        if [[ "$filename" == "$old" ]]; then
            continue
        fi
        basename_no_suffix="${filename%$old}"

        if [[ -z "$basename_no_suffix" || "$basename_no_suffix" == "." ]]; then
            continue
        fi

        new_filename="${basename_no_suffix}${new}"
        new_filepath="$dirpath/$new_filename"

        if [[ -e "$new_filepath" ]]; then
            echo "Warning: cannot rename '$filepath' → '$new_filepath' (target exists)"
            continue
        fi

        if mv -- "$filepath" "$new_filepath"; then
            echo "Renamed: $filepath -> $new_filepath"
            ((renamed_count++))
        else
            echo "Error: failed to rename '$filepath'"
        fi
    fi
done < <(find "$dir" -type f -print0)

echo ""
echo "Total files renamed: $renamed_count"
