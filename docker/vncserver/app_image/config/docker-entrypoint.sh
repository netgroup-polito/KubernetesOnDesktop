#!/bin/bash -xe
set -e

#Copy ssh secret and give right permissions
chmod go-w $HOME
mkdir -p $HOME/.ssh
chmod 755 $HOME/.ssh
cp $HOME/ssh_secret/authorized_keys $HOME/.ssh
chmod 600 $HOME/.ssh/authorized_keys
chown $USER $HOME/.ssh/authorized_keys

# Start ssh
service ssh start

### Switching to vncuser
su -p $USER --command "/opt/config/user-startup.sh"