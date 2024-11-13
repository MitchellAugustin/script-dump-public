# from https://github.com/tianocore/tianocore.github.io/wiki/Using-EDK-II-with-Native-GCC
# and https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions

# First, install packages with sudo apt-get install build-essential uuid-dev iasl git gcc-5 nasm python3-distutils
# then git clone https://github.com/tianocore/edk2
# Follow the instructions above. Once ready to do a rebuild on an already configured upstream environment (ex: after checking out a different branch/commit), run this script.

cd edk2
build

