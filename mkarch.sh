#!/bin/bash

usage() {
    echo "Usage: $0 -d dir_path -n name"
    echo "  -d dir_path  : path to directory to archive (required)"
    echo "  -n name      : name of self-extracting script (required)"
    exit 1
}

dir_path=""
name=""

while getopts "d:n:" opt; do
    case ${opt} in
        d )
            dir_path="$OPTARG"
            ;;
        n )
            name="$OPTARG"
            ;;
        \? )
            usage
            ;;
        : )
            echo "Error: -${OPTARG} requires an argument"
            usage
            ;;
    esac
done

if [ -z "$dir_path" ]; then
    echo "Error: -d option is required"
    usage
fi

if [ -z "$name" ]; then
    echo "Error: -n option is required"
    usage
fi

if [ ! -d "$dir_path" ]; then
    echo "Error: Directory '$dir_path' does not exist"
    exit 1
fi

temp_archive=$(mktemp /tmp/archive.XXXXXX.tar.gz)
tar -czf "$temp_archive" -C "$(dirname "$dir_path")" "$(basename "$dir_path")" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Error: Failed to create archive"
    rm -f "$temp_archive"
    exit 1
fi

cat > "$name" << 'SCRIPT_HEADER'
#!/bin/bash

extract_archive() {
    local output_dir="${1:-.}"
    
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        if [ $? -ne 0 ]; then
            echo "Error: Cannot create directory '$output_dir'"
            exit 1
        fi
    fi
    
    ARCHIVE_LINE=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$0")
    
    tail -n +$ARCHIVE_LINE "$0" | base64 -d | tar -xzf - -C "$output_dir"
    
    if [ $? -eq 0 ]; then
        echo "Archive extracted successfully to: $output_dir"
        exit 0
    else
        echo "Error: Failed to extract archive"
        exit 1
    fi
}

output_dir="."

while getopts "o:" opt; do
    case ${opt} in
        o )
            output_dir="$OPTARG"
            ;;
        \? )
            echo "Usage: $0 [-o output_directory]"
            exit 1
            ;;
    esac
done

extract_archive "$output_dir"

__ARCHIVE_BELOW__
SCRIPT_HEADER

base64 "$temp_archive" >> "$name"

rm -f "$temp_archive"

chmod a+x "$name"

if [ $? -eq 0 ]; then
    echo "Self-extracting archive '$name' created successfully"
    exit 0
else
    echo "Error: Failed to set execute permissions"
    exit 1
fi
