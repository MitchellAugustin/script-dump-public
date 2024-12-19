#!/bin/sh

set -e

sudo sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list
sudo apt update
sudo apt install fakeroot -y
sudo apt build-dep linux -y
