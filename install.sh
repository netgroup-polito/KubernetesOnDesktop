#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Installing Cloudify :)"

echo "Creating application folder"
mkdir -p /opt/Cloudify

echo "Copying application"
cp -r * /opt/Cloudify

echo "Creating the executable"
cp cloudify /usr/bin/

echo "Copying Cloudfox desktop entries and icon"
cp desktop/Cloudfox.desktop /home/$SUDO_USER/.local/share/applications/
cp desktop/Cloudfox.desktop /home/$SUDO_USER/Desktop/
cp desktop/cloudfox64.png /usr/share/icons/hicolor/64x64/apps/cloudfox.png

echo "Copying Cloudlibre desktop entries and icon"
cp desktop/Cloudlibre.desktop /home/$SUDO_USER/.local/share/applications/
cp desktop/Cloudlibre.desktop /home/$SUDO_USER/Desktop/
cp desktop/cloudlibre64.png /usr/share/icons/hicolor/64x64/apps/cloudlibre.png
