#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Openssh-server"
apt-get update 
apt-get install -y openssh-server
apt-get clean -y