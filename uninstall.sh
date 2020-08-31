#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Uninstalling Cloudify :("

echo -n "Deleting application folder..."
rm -rf /opt/Cloudify
echo "Done"

echo -n "Removing executables..."
rm -f /usr/bin/cloudify
rm -f /usr/bin/cloudify-uninstall
echo "Done"

echo -n "Removing old deploy files..."
rm -rf /tmp/Cloudify
echo "Done"

echo "Do you want to remove the 'k8s-on-desktop' namespace too?"
echo -n "WARNING: this will remove the 'Persistent Volume Claims' "
echo -n "from k8s and all the remote saved files (if any) for each "
echo "application WILL BE LOST!!!"
echo -n "If you want to, "
	  
while true; do
	read -p "please type 'yes' otherwise type 'no' ==> " -r reply

	if [[ $reply == "yes" ]]; then
		echo -n "Deleting k8s-on-desktop namespace..."
		kubectl delete namespace k8s-on-desktop &>/dev/null
		echo "Done"
		break;
	elif [[ $reply == "no" ]]; then
		echo "The k8s-on-desktop namespaced will not be deleted"
		break;
	fi
done

echo "KubernetesOnDesktop succesfully uninstalled."
echo ""
echo "WARNING:"
echo "If you added your user in the 'docker' group after the cloudify installation"
echo "and you don't need it anymore, please remember to remove it from 'docker' group"
echo "(e.g. by using 'gpasswd -d $SUDO_USER docker' command and logout/login the account"
echo "to take effect)."
