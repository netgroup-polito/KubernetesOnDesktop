#!/bin/bash
set -e

repo_owner="riccardoroccaro"
repo_branch="master"

function install_from_local_repository {
   echo "Installing Cloudify :)"
   echo -n "Creating application folder..."
   mkdir -p /opt/Cloudify
   echo "Done."

   echo -n "Copying application..."
   cp -rp * /opt/Cloudify
   echo "Done."

   echo -n "Creating the executables..."
   cp -p cloudify /usr/bin/
   cp -p uninstall.sh /usr/bin/cloudify-uninstall
   echo "Done."

   echo "Installation completed!"
   echo ""
   echo "WARNING:"
   echo "To make it work propery, remember to add your current user to 'docker' group"
   echo "(e.g. by using the command 'gpasswd -M $SUDO_USER docker' and logout/login the account"
   echo "to take effect) or to run it as root (e.g. by using 'sudo cloudify <args> <app>)."
}

function install_from_remote_repository {
   echo ""; echo ""
   echo "Welcome to KubernetesOnDesktop installation!"

   #Creating temp dir
   inst_tmp_dir=$(mktemp -d -t k8s-on-desktop-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)

   #Downloading the repository into temp dir
   cd $inst_tmp_dir
   echo "Downloading the repository..."
   curl -L https://github.com/$repo_owner/KubernetesOnDesktop/tarball/$repo_branch | tar xz &>/dev/null
   echo "Done."

   #Runing install.sh in local mode from the downloaded repository folder
   cd $(ls | grep KubernetesOnDesktop)
   ./install.sh
   cd /

   #Removing temp folder
   rm -fr $inst_tmp_dir
}

function main {
   if [[ $EUID -ne 0 ]]; then
      echo "This script must be run as root" 
      exit 1
   fi

   #Checking if it's a remote installation
   if [[ $1 == "--remote" ]]; then
      install_from_remote_repository
   else
      install_from_local_repository
   fi
}

main $@
