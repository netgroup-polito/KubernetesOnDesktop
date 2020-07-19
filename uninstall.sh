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

echo ""
echo "WARNING:"
echo "If you added your user in the 'docker' group after the cloudify installation"
echo "and you don't need it anymore, please remember to remove it from 'docker' group"
echo "(e.g. by using 'gpasswd -d $SUDO_USER docker' command and logout/login the account"
echo "to take effect)."
