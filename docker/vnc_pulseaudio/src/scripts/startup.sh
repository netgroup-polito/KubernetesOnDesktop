#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

### All operations that must be performed as root inside the container
# Start ssh
service ssh start

update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/firefox 200

### Switch user for the rest of the execution
su -p default --command "mkdir /home/default/.ssh && $STARTUPDIR/vnc_startup.sh"