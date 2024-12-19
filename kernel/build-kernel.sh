#!/bin/sh
#
#  Usage:
#    1. fetch linux kernel source in a folder, "linux"
#    2. get ready for build dependency of linux kernel
#    3. go to "linux"
#    4. cp /boot/<your current kernel config>.config ./.config
#    5. invoke this script
#
set -e

ncpu=$(nproc)

test -f .config
sed -i '/^CONFIG_SYSTEM_TRUSTED_KEYS=.*/d' .config
sed -i '/^CONFIG_SYSTEM_REVOCATION_KEYS=.*/d' .config
yes '' | make oldconfig

arch=$(uname -m)
case $arch in
    aarch64)
	image=arch/arm64/boot/Image.gz
	;;
    x86_64)
	image=arch/x86/boot/bzImage
	;;
    *)
	echo "ERROR: I don't know about $arch" 1>&2
	exit 1
esac
make -j$ncpu $(basename $image) modules
krel="$(make -s kernelrelease)"
sudo cp $image "/boot/vmlinuz-${krel}"
sudo cp .config "/boot/config-${krel}"
sudo make -j$ncpu modules_install INSTALL_MOD_STRIP=1
sudo mkinitramfs -o /boot/initrd.img-${krel} "$krel"
#sudo ln -sf "vmlinuz-${krel}" /boot/vmlinuz-update
#sudo ln -sf "initrd.img-${krel}" /boot/initrd.img-update
#sudo ln -sf "config-${krel}" /boot/config-update
sudo update-grub
#sudo reboot
