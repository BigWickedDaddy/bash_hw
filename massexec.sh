#!/bin/bash

dirpath="$(pwd)"
mask="*"
number=$(nproc)
command=""

usage() {
    echo "Usage: $0 [--path dirpath] [--mask mask] [--number number] command"
    echo "  --path dirpath   : directory path with files (default: current directory)"
    echo "  --mask mask      : file pattern mask (default: *)"
    echo "  --number number  : max parallel processes (default: CPU cores)"
    echo "  command          : executable file/script for processing (required)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            if [[ -n "$2" && "$2" != --* ]]; then
                dirpath="$2"
                shift 2
            else
                echo "Error: --path requires an argument"
                usage
            fi
            ;;
        --mask)
            if [[ -n "$2" && "$2" != --* ]]; then
                mask="$2"
                shift 2
            else
                echo "Error: --mask requires an argument"
                usage
            fi
            ;;
        --number)
            if [[ -n "$2" && "$2" != --* ]]; then
                number="$2"
                shift 2
            else
                echo "Error: --number requires an argument"
                usage
            fi
            ;;
        -*)
            echo "Error: Unknown option $1"
            usage
            ;;
        *)
            # Это должна быть команда
            command="$1"
            shift
            break
            ;;
    esac
done

if [ -z "$command" ]; then
    echo "Error: command is required"
    usage
fi

if [ ! -d "$dirpath" ]; then
    echo "Error: Directory '$dirpath' does not exist"
    exit 1
fi

if [ -z "$mask" ]; then
    echo "Error: mask cannot be empty"
    exit 1
fi

if ! [[ "$number" =~ ^[0-9]+$ ]] || [ "$number" -le 0 ]; then
    echo "Error: number must be a positive integer"
    exit 1
fi

if [ ! -f "$command" ]; then
    echo "Error: Command file '$command' does not exist"
    exit 1
fi

if [ ! -x "$command" ]; then
    echo "Error: Command file '$command' is not executable"
    exit 1
fi

if [[ "$command" != /* ]]; then
    command="$(realpath "$command")"
fi

if [[ "$dirpath" != /* ]]; then
    dirpath="$(realpath "$dirpath")"
fi

files=()
shopt -s nullglob
cd "$dirpath" || exit 1

for file in $mask; do
    if [ -f "$file" ]; then
        files+=("$dirpath/$file")
    fi
done

shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No files found matching pattern '$mask' in directory '$dirpath'"
    exit 0
fi

declare -a pids=()

file_index=0
total_files=${#files[@]}

echo "Processing $total_files files with max $number parallel processes..."

start_process() {
    local filepath="$1"
    "$command" "$filepath" &
    pids+=($!)
}

wait_for_slot() {
    wait -n
    
    local new_pids=()
    for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            new_pids+=("$pid")
        fi
    done
    pids=("${new_pids[@]}")
}

while [ $file_index -lt $total_files ]; do
    while [ ${#pids[@]} -lt $number ] && [ $file_index -lt $total_files ]; do
        start_process "${files[$file_index]}"
        ((file_index++))
    done
    
    if [ ${#pids[@]} -ge $number ]; then
        wait_for_slot
    fi
done

wait

echo "All files processed successfully"
