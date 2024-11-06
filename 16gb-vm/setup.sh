wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
#wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

sudo apt remove -y nvidia-utils-*-server linux-modules-nvidia-*-server-open-nvidia nvidia-compute-utils-*-server nvidia-fabricmanager-* nvidia-firmware-*-server-* nvidia-kernel-common-*-server nvidia-kernel-source-*-server-open
sudo apt update
sudo apt install -y qemu-system-x86
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-init cloud-image-utils ovmf python3 expect python3-pip python3-yaml

sudo usermod -aG libvirt ubuntu
sudo mkdir -p /vms
sudo chmod 777 -R /vms
cp noble-server-cloudimg-amd64.img /vms
sudo chmod 777 -R /vms

echo "Log out and log back in, then run ./spawn.sh 01"
