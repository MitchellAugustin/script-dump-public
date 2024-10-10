#!/bin/bash -x

set -e

EMBEDDED_SUBMODULES="CryptoPkg/Library/OpensslLib/openssl ArmPkg/Library/ArmSoftFloatLib/berkeley-softfloat-3 MdeModulePkg/Library/BrotliCustomDecompressLib/brotli"

do_build() {
    for submodule in $EMBEDDED_SUBMODULES; do
	git submodule update --depth 1 --init $submodule
    done
    git clean -x -f -d .
    git reset --hard HEAD
    cp -a /tmp/debian .
    QUILT_PATCHES=$(pwd)/debian/patches quilt push -a
    export PYTHON3_ENABLE=TRUE
    export PYTHON_COMMAND=python3
    TOOLCHAIN=GCC5
    make -C BaseTools
    source edksetup.sh
    fakeroot make -f debian/rules build-ovmf
    #sed -i '/Library\/MbedTlsLib\/mbedtls\/library/s/^/#/' CryptoPkg/CryptoPkg.dec
    #sed -i '/Library\/MbedTlsLib\/mbedtls\/include/s/^/#/' CryptoPkg/CryptoPkg.dec
    #build -a X64 -t ${TOOLCHAIN} -p OvmfPkg/OvmfPkgX64.dsc -DHTTP_BOOT_ENABLE=TRUE -DFD_SIZE_2MB -DNETWORK_IP6_ENABLE=TRUE -DNETWORK_TLS_ENABLE -DSECURE_BOOT_ENABLE=TRUE -b RELEASE -DTPM_ENABLE=TRUE -DSMM_REQUIRE=TRUE
}
cd edk2
do_build || exit 125 # 125 == skip, this one can not be tested

sudo cp debian/ovmf-install/OVMF_CODE_4M.fd /usr/share/OVMF/
#sudo cp ./Build/OvmfX64/RELEASE_${TOOLCHAIN}/FV/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.secboot.fd

git reset --hard HEAD # so automatic bisect can continue
PYTHONPATH=./debian/python python3 debian/tests/shell.py -k test_ovmf_ms_secure_boot_unsigned

