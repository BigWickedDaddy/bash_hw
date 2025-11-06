#!/bin/bash

usage() {
    echo "Usage:"
    echo "  $0 <directory>"
    echo "  $0 --dir <directory>"
    echo ""
    echo "Example:"
    echo "  $0 /home/user/docs"
    echo "  $0 --dir /home/user/docs"
    exit 1
}

get_suffix() {
    local filename="$1"

    if [[ "$filename" == .* ]]; then
        local rest="${filename#.}"

        if [[ -z "$rest" ]]; then
            echo "no suffix"
            return
        fi

        if [[ "$rest" == *.* ]]; then
            echo ".${rest##*.}"
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

dir=""

if [[ $# -eq 1 && "$1" != --* ]]; then
    dir="$1"
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir) dir="$2"; shift 2 ;;
            -h|--help) usage ;;
            *) echo "Error: unknown option $1"; usage ;;
        esac
    done
fi

if [[ -z "$dir" ]]; then
    echo "Error: directory is required"
    usage
fi

if [[ ! -d "$dir" ]]; then
    echo "Error: '$dir' is not a directory or does not exist"
    exit 1
fi

declare -A suffix_count

while IFS= read -r -d '' fp; do
    fname=$(basename "$fp")
    suf=$(get_suffix "$fname")
    ((suffix_count["$suf"]++))
done < <(find "$dir" -type f -print0)

if [[ ${#suffix_count[@]} -eq 0 ]]; then
    echo "No files found in '$dir'"
    exit 0
fi

{
    for key in "${!suffix_count[@]}"; do
        printf "%d\t%s\n" "${suffix_count[$key]}" "$key"
    done
} | sort -rn -k1,1 | while IFS=$'\t' read -r cnt key; do
    printf "%s: %d\n" "$key" "$cnt"
done
