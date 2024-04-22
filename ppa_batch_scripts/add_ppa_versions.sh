#!/bin/bash

# Iterate over all debian/changelog files in pwd
for file in */debian/changelog; do
    # Check if the file exists and is not empty
    if [ -s "$file" ]; then
        # Get the first line, package, and version of the original changelog
        first_line=$(head -n 1 "$file")
        package=$(echo "$first_line" | cut -d' ' -f1)
        version=$(echo "$first_line" | cut -d' ' -f2)
        # Append "ppa1" to the version code
        version_with_ppa1="${version::-1}ppa1${version: -1}"
        # Create new first line with the new version code
        new_first_line="${package} ${version_with_ppa1} UNRELEASED; urgency=medium"
        # Add new lines to changelog
        sed -i "1s/^/ -- Mitchell Augustin <mitchell.augustin@canonical.com> Mon, 22 Apr 2024 15:22:00 -0500 \n\n/" "$file"
        sed -i "1s/^/\n  * Packaged for PPA\n\n/" "$file"
        sed -i "1s/^/$new_first_line\n/" "$file"
    fi
done

