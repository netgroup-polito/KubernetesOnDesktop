#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

apt -y autoremove
apt -y autoclean