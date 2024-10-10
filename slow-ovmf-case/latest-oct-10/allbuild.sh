#!/bin/bash -x

set -e

cd edk2

#git reset --hard HEAD # so automatic bisect can continue
#QUILT_PATCHES=$(pwd)/debian/patches quilt push -a # hopefully they apply cleanly!
fakeroot make -f debian/rules build-ovmf

sudo cp ./Build/OvmfX64/RELEASE_${TOOLCHAIN}/FV/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE_4M.fd

#git reset --hard HEAD # so automatic bisect can continue
PYTHONPATH=./debian/python python3 debian/tests/shell.py -k test_ovmf_ms_secure_boot_unsigned

