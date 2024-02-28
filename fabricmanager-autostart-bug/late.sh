#!/bin/sh

set -e
set -x

export DEBIAN_FRONTEND=noninteractive
UBUNTU_VER="$(lsb_release -rs)"

install_gpu_drivers() {
    case $UBUNTU_VER in
        # NOTE!!
        # When bumping the version, you may need to update the corresponding a-c-t test job i.e.
        # - autotest-client-tests/ubuntu_nvidia_fs/nvidia-fs/00-vars
        18.04|20.04)
            NVIDIA_DRIVER_VERSION=470-server
            ;;
        *)
            NVIDIA_DRIVER_VERSION=525-server
            ;;
    esac

    if lspci | grep "NVIDIA" | grep -q "V100"; then
        NVIDIA_DRIVER_VERSION_VARIANT="${NVIDIA_DRIVER_VERSION}"
    else
        NVIDIA_DRIVER_VERSION_VARIANT="${NVIDIA_DRIVER_VERSION}"
    fi

    pkgs="nvidia-utils-${NVIDIA_DRIVER_VERSION}"
    pkgs="${pkgs} nvidia-kernel-source-${NVIDIA_DRIVER_VERSION_VARIANT}"
    # For nvidia flavor it is a bit tricky since the nomenculate is not consistent
    # with generic and other flavors fully. For example,
    #    $ dpkg-query -W -f '${Package}\n' linux-nvidia*
    #    linux-nvidia
    #    linux-nvidia-headers-5.15.0-1015
    #    linux-nvidia-source-5.15.0
    #    linux-nvidia-tools
    # but the generic headers would look like
    #    linux-headers-generic
    #    linux-headers-5.15.0-25-generic
    # even more, this is the hwe flavor for example:
    #    linux-headers-generic-hwe-20.04
    #
    # So using similar pattern to generalize regex will not work.
    #
    # Lastly, brace expansion is not POSIX. Dash does not support brace expansion
    # so we do not use something like:
    #     linux-{generic,nvidia}
    # and let us use the other approaches like a for-loop instead.
    for possible_flavor_pattern in \
	linux-generic \
	linux-generic-64k \
	linux-nvidia \
	"linux-generic-*-hwe-[0-9][0-9]\.[0-9][0-9]" \
	"linux-nvidia-*-hwe-[0-9][0-9]\.[0-9][0-9]"; do
        for metapkg in $(dpkg-query -W -f '${Package}\n' "${possible_flavor_pattern}"); do
            flavor=${metapkg#linux-}
            pkgs="$pkgs linux-modules-nvidia-${NVIDIA_DRIVER_VERSION}-${flavor}"
            echo $pkgs
        done
    done
    pkgs="${pkgs} nvidia-driver-${NVIDIA_DRIVER_VERSION_VARIANT}"
}

install_mellanox_ofed() {
    if [ "$(dmidecode -s system-product-name)" = "DGXH100" ]; then
	# https://warthogs.atlassian.net/browse/NVDGX-675
	return 0
    fi
    local MLNX_REPO="https://linux.mellanox.com/public/repo/mlnx_ofed"
    # NOTE!!
    # When bumping the version, you may need to update the corresponding a-c-t test job i.e.
    # - autotest-client-tests/ubuntu_dgx_mofed_build/expected-mofed-modules
    # - autotest-client-tests/ubuntu_nvidia_fs/nvidia-fs/00-vars
    case $UBUNTU_VER in
	22.04)
	    MELLANOX_OFED_VERSION=23.10-1.1.9.0
	    ;;
        20.04)
            MELLANOX_OFED_VERSION=5.4-3.7.5.0
            ;;
        18.04)
            MELLANOX_OFED_VERSION=4.9-4.1.7.0
            ;;
        *)
            return 0
    esac
    mlnx_url="${MLNX_REPO}/${MELLANOX_OFED_VERSION}/ubuntu${UBUNTU_VER}/mellanox_mlnx_ofed.list"

    wget -O - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | \
        apt-key add -
    wget -O /etc/apt/sources.list.d/mellanox_mlnx_ofed.list \
        "$mlnx_url"
    apt update
    apt install mlnx-ofed-kernel-only -y
    # Workaround issue w/ knem-dkms where it only builds against the running
    # kernel, which is not necessarily the installed kernel.
    # http://partners.nvidia.com/bug/viewbug/3409217
    /usr/lib/dkms/dkms_autoinstaller start "$(linux-version list | linux-version sort | tail -1)"
    # Disable knem autoloading to avoid oops (LP: #1929187)
    sed -i 's/knem/#knem # Commented out by MAAS preseed/' \
        /etc/modules-load.d/modules.conf

    update-initramfs -u
}

install_fabric_manager() {
    apt install -y nvidia-fabricmanager-${NVIDIA_DRIVER_VERSION%-server}
    #systemctl enable nvidia-fabricmanager
}

install_systemd_unit_disable_MIG() {
    cat > disable-MIG.service << EOF
[Unit]
Description=Disable NVIDIA MIG mode by default for project of DGX performance testing
# Apply gpu-reset in case the gpu is in the status of "In use by another
# client". If gpu is in that status, resetting gpu will exit with failure
# like this:
#     Jan 11 01:19:54 blanka nvidia-smi[5799]: The following GPUs could not be reset:
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:07:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:0F:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:47:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:4E:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:87:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:90:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:B7:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]:   GPU 00000000:BD:00.0: In use by another client
#     Jan 11 01:19:54 blanka nvidia-smi[5799]: 8 devices are currently being used by one or more other processes (e.g., Fabric Manager, CUDA application, ...)
#     Jan 11 01:19:54 blanka systemd[1]: disable-MIG.service: Control process exited, code=exited, status=255/EXCEPTION
#     Jan 11 01:19:54 blanka systemd[1]: disable-MIG.service: Failed with result 'exit-code'.
#     Jan 11 01:19:54 blanka systemd[1]: Failed to start Disable NVIDIA MIG mode by default for project of DGX performance testing.
#
# This message is observed at the first boot after deploying, and have observed
# after the other boots.  I believe the other processes like fabric manager may
# need to take more time at first launching, and make this race condition.  The
# real cause is still unknown yet, but this line helps. I tested several
# deployments and boots to verify it helps.
Before=nvidia-fabricmanager.service

[Service]
Type=oneshot
ExecCondition=sh -c '/usr/bin/nvidia-smi --query-gpu=mig.mode.current --format=csv,noheader | grep -q Enabled'
ExecStartPre=/usr/bin/nvidia-smi
ExecStart=/usr/bin/nvidia-smi -mig 0
# To make sure the change take effect, otherwise we may have this warning (reproducing rate, 3 reboots out of 3):
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:07:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:07:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:0F:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:0F:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:47:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:47:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:4E:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:4E:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:87:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:87:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:90:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:90:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:B7:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:B7:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Warning: MIG mode is in pending disable state for GPU 00000000:BD:00.0:Timeout
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: Reboot the system or try nvidia-smi --gpu-reset to make MIG mode effective on GPU 00000000:BD:00.0
#     Jan 19 12:30:10 blanka nvidia-smi[4765]: All done.
ExecStartPost=-/usr/bin/nvidia-smi --gpu-reset
RemainAfterExit=false
ExecStop=/usr/bin/nvidia-smi
StandardOutput=journal

[Install]
WantedBy=default.target
EOF
    mv disable-MIG.service /etc/systemd/system
    systemctl daemon-reload
    systemctl enable disable-MIG
}

if [ "$(dmidecode -s baseboard-product-name)" = "DGXA100" ] &&
       [ "$(ls /sys/bus/node/devices | wc -l)" -ne 8 ]; then
    echo "ERROR: DGX A100 systems should be configured with NPS=4 for performance testing"
    echo "Please correct the setting in the BIOS Setup Menu:"
    echo "  Advanced->AMD CBS->DF Common Options->Advanced->Memory Addressing"
    exit 1
fi


if [ "$(dmidecode -s baseboard-product-name)" = "DGXA100" ]; then
    echo "Disable MIG mode for DGXA100 by default for tensorflow performance testing."
    echo "On installing systemd unit to disable MIG by default..."
    install_systemd_unit_disable_MIG
    echo "Installed. When booting, systemd will try to disable MIG mode now."
fi

# Checks for a 3D controller (class 0302) from vendor Nvidia (vendor ID 10de),
# then sets the exit code based on whether the lspci call had any output
if [ -n "$(lspci -d 10de::0302)" ]; then
    echo "Nvidia 3D Controller detected, installing GPU drivers"
    install_gpu_drivers
fi

pkgs="$pkgs ipmitool"

apt install -y ${pkgs}

if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    install_fabric_manager
    install_mellanox_ofed
fi

apt remove --purge irqbalance -y

# Frequent MAAS deploys quickly fill the SEL, which can cause us to
# fail to capture events we need for debugging issues w/ NV Support
ipmitool sel clear || true
