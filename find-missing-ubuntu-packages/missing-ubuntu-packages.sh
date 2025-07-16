#!/bin/bash

# Print all packages in <input_file> that aren't present in any Ubuntu release
# Usage: ./missing-ubuntu-packages.sh input.txt

input_file="$1"

if [[ -z "$input_file" || ! -f "$input_file" ]]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# Process packages from input
grep '^Package:' "$input_file" | cut -d' ' -f2 | while read -r pkg; do
    # Check if the package exists in any Ubuntu release
    if ! rmadison "$pkg" | grep -q "ubuntu"; then
        echo "$pkg"
    fi
done

