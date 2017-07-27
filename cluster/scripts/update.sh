#!/bin/bash
set -e

# update & upgrade
unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y -qq -o Dpkg::Options::="--force-confnew" upgrade

# update kernel packages without using dist-upgrade
apt-get -y -qq -o Dpkg::Options::="--force-confnew" install linux-aws linux-headers-aws linux-image-aws

# install useful packages
apt-get -y -qq install \
    tmux    \
    tree    \
    jq      \
    awscli  \
    openjdk-8-jdk-headless

# clean up
apt-get -y -qq autoclean
apt-get -y -qq autoremove
