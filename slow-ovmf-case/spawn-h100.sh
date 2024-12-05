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
qemu-img create -b jammy-server-cloudimg-amd64.img -F qcow2 -f qcow2 ${VM}-vda.qcow2 60G


virt-install --name 4gpu-vm-2 --vcpus vcpus=16,maxvcpus=16 --memory 943616 --numatune 0,mode=strict --iothreads 1,iothreadids.iothread0.id=1 --cputune emulatorpin.cpuset=55,167,iothreadpin0.iothread=1,iothreadpin0.cpuset=54,166,vcpupin0.vcpu=0,vcpupin0.cpuset=16,vcpupin1.vcpu=1,vcpupin1.cpuset=128,vcpupin2.vcpu=2,vcpupin2.cpuset=17,vcpupin3.vcpu=3,vcpupin3.cpuset=129,vcpupin4.vcpu=4,vcpupin4.cpuset=18,vcpupin5.vcpu=5,vcpupin5.cpuset=130,vcpupin6.vcpu=6,vcpupin6.cpuset=19,vcpupin7.vcpu=7,vcpupin7.cpuset=131,vcpupin8.vcpu=8,vcpupin8.cpuset=20,vcpupin9.vcpu=9,vcpupin9.cpuset=132,vcpupin10.vcpu=10,vcpupin10.cpuset=21,vcpupin11.vcpu=11,vcpupin11.cpuset=133,vcpupin12.vcpu=12,vcpupin12.cpuset=22,vcpupin13.vcpu=13,vcpupin13.cpuset=134,vcpupin14.vcpu=14,vcpupin14.cpuset=23,vcpupin15.vcpu=15,vcpupin15.cpuset=135 --os-variant ubuntu22.04 --graphics none --noautoconsole --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader_ro=yes,loader_type=pflash --console pty,target_type=serial --network network:default --import --disk ${VM}-vda.qcow2 --disk ${VM}-seed.qcow2,format=qcow2,driver.queues=16,driver.iothread=1 --host-device 1b:00.0,address.type=pci --host-device 61:00.0,address.type=pci --host-device c3:00.0,address.type=pci --host-device df:00.0,address.type=pci

