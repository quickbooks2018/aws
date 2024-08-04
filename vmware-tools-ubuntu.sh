#!/bin/bash

# Update the system
sudo apt update && sudo apt upgrade -y

# Create mount directory
sudo mkdir -p /mnt/cdrom

# Mount VMware Tools ISO
sudo mount /dev/cdrom /mnt/cdrom

# Copy VMware Tools to home directory
cp /mnt/cdrom/VMwareTools-*.tar.gz ~/

# Extract VMware Tools
tar -xzvf ~/VMwareTools-*.tar.gz

# Install VMware Tools
sudo ~/vmware-tools-distrib/vmware-install.pl -d

# Reboot the system
sudo reboot
