#!/bin/bash
#
# A script run in User Data that can be used to configure the Bastion Host. It just installs the latest OS and security
# updates.

set -e

# TODO: A better way to handle this is to create a Packer template that runs these updates
echo 'Installing latest OS and security updates'
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

# Create a file to check later with automated tests
echo "Hello, world!" > /home/ubuntu/hello.txt
