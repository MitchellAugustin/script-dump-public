#!/bin/bash

sudo apt build-dep -y gcc-14
# Step 1: Get the source for gcc-14
if ! apt-get source gcc-14; then
  echo "Failed to fetch source for gcc-14. Ensure sources are configured correctly."
  exit 1
fi

# Step 2: Navigate to the gcc-14 source directory
src_dir=$(find . -maxdepth 1 -type d -name "gcc-14*" | head -n 1)
if [ -z "$src_dir" ]; then
  echo "gcc-14 source directory not found."
  exit 1
fi

cd "$src_dir" || exit

# Step 3: Apply the patch
patch_file="0001-Add-sve-gcc.patch"
if [ ! -f "../$patch_file" ]; then
  echo "Patch file $patch_file not found in the parent directory."
  exit 1
fi

if patch -p1 < "../$patch_file"; then
  echo "Patch applied successfully."
else
  echo "Failed to apply patch."
  exit 1
fi

# Step 4: Build the package
if dpkg-buildpackage -us -uc -rfakeroot -b; then
  echo "Successfully built gcc-14 package."
else
  echo "Failed to build gcc-14 package."
  exit 1
fi

