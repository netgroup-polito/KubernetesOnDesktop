#!/bin/bash -xe
set -e

# Start ssh
service ssh start

### Switching to vncuser
su -p $USER --command "/opt/config/user-startup.sh"