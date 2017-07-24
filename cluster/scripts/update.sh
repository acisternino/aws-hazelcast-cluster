#!/bin/bash
set -e
sleep 30

# Update script for the Bastion Host

# Update & upgrade the instance
unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y -qq -o Dpkg::Options::="--force-confnew" upgrade

# Install useful packages
apt-get -y -qq install tmux tree jq

# Clean up
apt-get -y -qq autoclean
apt-get -y -qq autoremove
