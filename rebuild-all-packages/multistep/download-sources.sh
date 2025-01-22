#!/bin/bash

# Script 1: Download source packages and apply modifications
# Exit on any error
set -e

# Create a working directory
WORKDIR=$(pwd)/tmp
mkdir -p "$WORKDIR"
echo "Working directory: $WORKDIR"

# Update package lists to ensure source packages are available
sudo apt update

# Install required tools for handling packages
sudo apt install -y dpkg-dev devscripts

# Get a list of installed packages
installed_packages=$(dpkg-query -W -f='${binary:Package} ${Version}\n')

# Change to the working directory
cd "$WORKDIR"

# Loop through each package to download source and apply modifications
while read -r package version; do
    if [[ "$version" != *+arm82a* && "$version" != *+armv82a* ]]; then
        echo "Processing package: $package"

        # Download the source package
        if apt-get source "$package"; then
            # Find the extracted source directory
            sourcedir=$(find . -maxdepth 1 -type d -name "$package-*" | sort | tail -n 1)

            if [ -d "$sourcedir" ]; then
                echo "Modifying package: $package"
                cd "$sourcedir"

                # Modify changelog to append +arm82a to the version
                if [ -f debian/changelog ]; then
                    echo "Modifying changelog for: $package"
                    printf "\n" | dch --local +arm82a "Rebuilt for arm82a."
                else
                    echo "Failed - No changelog found for $package. Skipping changelog modification."
                fi

                # Adjust strict version dependencies to "greater than or equal to"
                if [ -f debian/control ]; then
                    echo "Not Adjusting version dependencies for: $package"
		    #sed -i -E '/debhelper-compat/!s/([^(]*)=([^)]*)/\1 (>= \2)/g' debian/control

                else
                    echo "No control file found for $package. Skipping dependency adjustment."
                fi

                cd "$WORKDIR"
            else
                echo "Failed - Source directory for $package not found. Skipping."
            fi
        else
            echo "Failed to download source for $package. Skipping."
        fi
    else
        echo "Skipping package $package as it already contains '+arm82a' or '+armv82a' in the version."
    fi

done <<< "$installed_packages"

# Script completed
echo "Source downloading and modifications complete. You can now build the packages with a separate script."

