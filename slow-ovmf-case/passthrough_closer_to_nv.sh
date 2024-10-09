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

virt-install --name ${VM} --memory 943616 --graphics none --noautoconsole --numatune 0,mode=strict --iothreads 1,iothreadids.iothread0.id=1 --cputune emulatorpin.cpuset=55,127,iothreadpin0.iothread=1,iothreadpin0.cpuset=54,126,vcpupin0.vcpu=0,vcpupin0.cpuset=16,vcpupin1.vcpu=1,vcpupin1.cpuset=125,vcpupin2.vcpu=2,vcpupin2.cpuset=17,vcpupin3.vcpu=3,vcpupin3.cpuset=124,vcpupin4.vcpu=4,vcpupin4.cpuset=18,vcpupin5.vcpu=5,vcpupin5.cpuset=123,vcpupin6.vcpu=6,vcpupin6.cpuset=19,vcpupin7.vcpu=7,vcpupin7.cpuset=122,vcpupin8.vcpu=8,vcpupin8.cpuset=20,vcpupin9.vcpu=9,vcpupin9.cpuset=121,vcpupin10.vcpu=10,vcpupin10.cpuset=21,vcpupin11.vcpu=11,vcpupin11.cpuset=120,vcpupin12.vcpu=12,vcpupin12.cpuset=22,vcpupin13.vcpu=13,vcpupin13.cpuset=120,vcpupin14.vcpu=14,vcpupin14.cpuset=23,vcpupin15.vcpu=15,vcpupin15.cpuset=119 \
             --console pty,target_type=serial --vcpus 16,maxvcpus=16 \
	     --cpu cell0.memory=$((8*1024*1024)),cell0.cpus=0-3 \
             --machine q35 --osinfo name=ubuntujammy \
             --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader_ro=yes,loader_type=pflash \
             --disk ${VM}-vda.qcow2 --disk ${VM}-seed.qcow2 --import \
	     --host-device=${GPU01} \
	     --host-device=${GPU02} \
	     --host-device=${GPU03} \
	     --host-device=${GPU04}

 #--vcpus 4,cpuset=$cpusetstart-$cpusetend \
	     #--cpu host-passthrough,cache.mode=passthrough,cell0.memory=$((8*1024*1024)),cell0.cpus=0-3 \

