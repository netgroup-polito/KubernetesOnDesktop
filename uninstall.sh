#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Uninstalling Cloudify :("

echo "Deleting application folder"
rm -rf /opt/Cloudify

echo "Removing executable"
rm -f /usr/bin/cloudify

echo "Removing Cloudfox desktop entries and icon" 
rm -f /home/$SUDO_USER/.local/share/applications/Cloudfox.desktop \
	/home/$SUDO_USER/Desktop/Cloudfox.desktop \
	/usr/share/icons/hicolor/64x64/apps/cloudfox.png

echo "Removing Cloudlibre desktop entries and icon" 
rm -f /home/$SUDO_USER/.local/share/applications/Cloudlibre.desktop \
	/home/$SUDO_USER/Desktop/Cloudlibre.desktop \
	/usr/share/icons/hicolor/64x64/apps/cloudlibre.png

echo "Removing old deploy files"
rm -rf /tmp/Cloudify