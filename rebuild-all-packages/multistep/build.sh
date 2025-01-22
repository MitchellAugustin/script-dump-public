#!/bin/bash

# Get the current directory
current_dir=$(pwd)/tmp

# Iterate through all subdirectories in the current directory
for dir in */; do
  if [ -d "$dir" ]; then
    echo "Entering directory: $dir"

    # Change into the directory
    cd "$dir" || continue

    # Run the dpkg-buildpackage command
    if dpkg-buildpackage -us -uc -rfakeroot -b; then
      echo "Successfully built package in $dir"
    else
      echo "Error building package in $dir"
    fi

    # Change back to the original directory
    cd "$current_dir" || exit
  fi

done

