#!/bin/bash

if [ -z "$1" ]; then
	echo "Error: No GPU index provided"
	echo "Usage: $0 <GPU index>"
	exit 1
fi

VM=testbox$1

virsh destroy $VM
virsh undefine $VM --nvram
rm -f *.qcow2

cat > user-data <<EOF
#cloud-config
password: passw0rd
chpasswd: { expire: False }
hostname: ${VM}
package_update: true
ssh_import_id: [mitchellaugustin]
version: 2
EOF

cloud-localds ${VM}-seed.qcow2 user-data -d qcow2
qemu-img create -b jammy-server-cloudimg-amd64.img -F qcow2 -f qcow2 ${VM}-vda.qcow2 30G

GPU01=pci_0000_01_00_0
GPU02=pci_0000_47_00_0
GPU03=pci_0000_81_00_0
GPU04=pci_0000_c2_00_0

GPU_VAR="GPU$1"

input_number_noleadzero=$(echo "$1" | sed 's/^0*//')

cpusetstart=$((0 + (4 * $input_number_noleadzero)))
cpusetend=$((3 + (4 * $input_number_noleadzero)))

echo "CPU set: $cpusetstart-$cpusetend"

echo "GPU: ${!GPU_VAR}"

virt-install --name ${VM} --memory $((128*1024*1024)) --graphics vnc,listen=0.0.0.0 --noautoconsole \
             --console pty,target_type=serial --vcpus 4,cpuset=$cpusetstart-$cpusetend \
             --machine q35 --osinfo name=ubuntujammy \
	     --cpu host-passthrough,cache.mode=passthrough,cell0.memory=$((8*1024*1024)),cell0.cpus=0-3 \
             --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader_ro=yes,loader_type=pflash \
             --disk ${VM}-vda.qcow2 --disk ${VM}-seed.qcow2 --import \
	     --host-device=${GPU01} \
	     --host-device=${GPU02} \
	     --host-device=${GPU03} \
	     --host-device=${GPU04}

