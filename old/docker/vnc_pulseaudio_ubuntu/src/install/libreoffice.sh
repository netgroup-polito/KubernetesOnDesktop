#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Libreoffice"
apt-get update
apt-get install -y libreoffice
apt-get clean -y