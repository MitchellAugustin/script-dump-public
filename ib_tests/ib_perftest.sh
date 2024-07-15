#!/bin/bash
#
# This is a smoke test for an IB setup (kernel modules, verbs layer, hardware)
# using perftest.
# 
# I lifted most of this from Dann's ib_peermem test, but since I am not focused
# on the Nvidia peermem modules for future MOFED version testing, I have
# removed those components. (Given that nvidia-peermem has been deprecated,
# I do not see it as necessary for the scope of what I want to test here,
# which is basic MOFED software/hardware functionality.)
# https://discourse.ubuntu.com/t/nvidia-gpudirect-over-infiniband-migration-paths/44425
# 
# Prerequisites:
#   - nvidia-driver-<branch> package installed; nvidia driver loaded
#   - nvidia-fabricmanager, if required, installed and started
#   - 2 local IB ports connected back-to-back
#
# Authors: 
#  * dann frazier <dann.frazier@canonical.com>
#  * Mitchell Augustin <mitchell.augustin@canonical.com>
set -e
set -x

export DEBCONF_FRONTEND="noninteractive"
export DEBIAN_PRIORITY="critical"

hostcfg="hosts.d/$HOSTNAME"
if [ -e "$hostcfg" ]; then
    source "$hostcfg"
else
    echo "ERROR: No configuration file found for $HOSTNAME" 1>&2
    exit 1
fi

sudo_apt() {
    sudo --preserve-env=DEBCONF_FRONTEND,DEBIAN_PRIORITY apt "$@"
}

cleanup() {
    { [ -n "$srvpid" ] && test -d "/proc/$srvpid"; } || \
	sudo kill "$srvpid" || /bin/true
    [ -z "$tmpdir" ] || rm -rf "$tmpdir"
    sudo ip addr del dev "$SERVER_IFACE" "$SERVER_IP" || /bin/true
    sudo ip netns exec peermemclient \
	 ip addr del dev "$CLIENT_IFACE" "$CLIENT_IP" || /bin/true
    sudo ip netns delete peermemclient || /bin/true
}
trap cleanup EXIT

ubuntu_mirror() {
    local arch
    arch="$(dpkg --print-architecture)"
    case $arch in
	amd64|i386)
	    echo "http://archive.ubuntu.com/ubuntu"
	    return
	    ;;
	*)
	    echo "http://ports.ubuntu.com/ubuntu-ports"
	    return
	    ;;
    esac
}

use_cuda_needs_devid() {
    if ib_write_bw --help | grep use_cuda=; then
	return 0
    fi
    return 1
}

usage() {
    echo "Usage: $0 [-m <peermem|dma_buf>]"
}

while getopts "hm:" arg; do
    case $arg in
	h)
	    echo "Usage: $0 [-m <peermem|dma_buf>]"
	    exit 0
	    ;;
	m)
	    mode="$OPTARG"
	    if [ "$mode" != "peermem" ] && [ "$mode" != "dma_buf" ]; then
		echo "Error: Invalid mode: $mode" 1>&2
		usage 1>&2
		exit 1
	    fi
	    ;;
	*)
	    usage 1>&2
	    ;;
    esac
done

# Avoid dpkg lock contention
sudo service unattended-upgrades stop || true

for ibdev in /sys/class/infiniband/*; do
    # is this lisp?
    bdf="$(basename "$(dirname "$(dirname "$(readlink "$ibdev")")")")"
    case "$bdf" in
	"$CLIENT_IB_BDF")
	    client_ib_dev="$(basename "$ibdev")"
	    ;;
	"$SERVER_IB_BDF")
	    server_ib_dev="$(basename "$ibdev")"
	    ;;
    esac
done

if [ -z "$client_ib_dev" ]; then
    echo "ERROR: Could not find client infiniband device" 1>&2
    exit 1
fi
if [ -z "$server_ib_dev" ]; then
    echo "ERROR: Could not find server infiniband device" 1>&2
    exit 1
fi

sudo rdma system set netns exclusive
sudo ip netns add peermemclient
sudo rdma dev set "$client_ib_dev" netns peermemclient
sudo ip netns exec peermemclient ip link set dev lo up
sudo ip link set netns peermemclient "$CLIENT_IFACE"
sudo ip netns exec peermemclient ip addr add dev "$CLIENT_IFACE" "$CLIENT_IP"
sudo ip netns exec peermemclient ip link set dev "$CLIENT_IFACE" up

sudo ip addr add dev "$SERVER_IFACE" "$SERVER_IP"
sudo ip link set dev "$SERVER_IFACE" up

if [ -z "$mode" ]; then
    # IB Peer Memory is out of tree kernel patch carried in Ubuntu
    # 4.15 -> 6.5. It is also provided by the Mellanox OFED modules.
    if grep -q ib_register_peer_memory_client /proc/kallsyms; then
	mode=peermem
    else
	mode=dma_buf
    fi
fi

sudo modprobe ib_umad # bro?
#if [ "$mode" = "peermem" ]; then
    #sudo modprobe nvidia-peermem
#fi

sudo_apt install -y opensm
sudo service opensm start || sudo service opensmd start

sudo ib_write_bw -a -d "$server_ib_dev" &
srvpid=$!
# Give server a chance to start up
sleep 5
sudo ip netns exec peermemclient ib_write_bw -a \
     -d "$client_ib_dev" "${SERVER_IP%/*}"

