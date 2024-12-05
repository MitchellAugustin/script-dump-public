wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

sudo apt remove -y nvidia-utils-*-server linux-modules-nvidia-*-server-open-nvidia nvidia-compute-utils-*-server nvidia-fabricmanager-* nvidia-firmware-*-server-* nvidia-kernel-common-*-server nvidia-kernel-source-*-server-open
sudo apt update
sudo apt install -y qemu-system-x86
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-init cloud-image-utils ovmf python3 expect python3-pip python3-yaml

