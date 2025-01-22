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
sudo DEBIAN_FRONTEND=noninteractive apt install -y dpkg-dev devscripts

# Get a list of installed packages
installed_packages=$(dpkg-query -W -f='${binary:Package} ${Version}\n')

# Change to the working directory
cd "$WORKDIR"

apt list --installed > pkg_list_orig.txt

# Loop through each package to download source and apply modifications
while read -r package version; do
    if [[ "$version" != *+arm82a* ]]; then
        echo "Processing package: $package"

	if [[ "$package" != *linux-image* && "$package" != "*mingw*" ]]; then
		sudo DEBIAN_FRONTEND=noninteractive apt-get build-dep -y "$package" || true
	else
		echo "Skipping linux kernel package"
	fi
    else
        echo "Skipping package $package as it already contains '+arm82a' in the version."
    fi

done <<< "$installed_packages"

echo "build-deps for this step installed"

apt list --installed > pkg_list_new.txt

if cmp -s "pkg_list_old.txt" "pkg_list_new.txt"; then
  echo "No more build deps - all packages installed"
else
  echo "More build deps remain - re-running this script"
  ./build-deps.sh
fi



# Script completed

