#!/bin/bash

if [ -z "$1" ]; then
	echo "Error: No GPU index provided"
	#echo "Usage: $0 <GPU index> <GPU PCI address>"
	echo "Usage: $0 <GPU index>"
	exit 1
fi

#if [ -z "$2" ]; then
#	echo "Error: No GPU address provided"
#	echo "Usage: $0 <GPU index> <GPU PCI address>"
#	exit 1
#fi


VM=$(hostname)-testbox$1

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

cloud-localds /vms/${VM}-seed.qcow2 user-data -d qcow2
qemu-img create -b /vms/noble-server-cloudimg-amd64.img -F qcow2 -f qcow2 /vms/${VM}-vda.qcow2 80G

GPU_ADDR=$2

input_number_noleadzero=$(echo "$1" | sed 's/^0*//')

cpusetstart=$((0 + (4 * $input_number_noleadzero)))
cpusetend=$((3 + (4 * $input_number_noleadzero)))

echo "CPU set: $cpusetstart-$cpusetend"

echo "GPU: ${!GPU_VAR}"

virt-install --boot uefi,firmware.feature0.name=enrolled-keys,firmware.feature0.enabled=no,firmware.feature1.name=secure-boot,firmware.feature1.enabled=yes --name ${VM} --memory 16384 --graphics vnc,listen=0.0.0.0 --noautoconsole \
             --console pty,target_type=serial --vcpus 4,cpuset=$cpusetstart-$cpusetend \
             --machine q35 --osinfo name=ubuntujammy \
	     --cpu host-passthrough,cache.mode=passthrough,cell0.memory=$((8*1024*1024)),cell0.cpus=0-3 \
             --disk /vms/${VM}-vda.qcow2 --disk /vms/${VM}-seed.qcow2 --import #\
	     #--host-device=${GPU_ADDR}

#MAC=$(virsh dumpxml $VM | grep 'mac address' | cut -f 2 -d "'")
#echo "MAC: $MAC"
#power_parameters='{"power_pass":"ubuntu","power_address":"qemu+ssh://ubuntu@'$(ip addr | grep -oP 'inet 10\.229\.\d+\.\d+' | awk '{print $2}')'/system","power_id":"'$VM'"}'
#maas testbox machines create architecture=amd64/generic mac_addresses=$MAC hostname=$VM power_type=virsh power_parameters="$power_parameters" | ./extract_maas_id.py >> vm_maas_ids.txt

#--boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader_ro=yes,loader_type=pflash \
