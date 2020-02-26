#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install TigerVNC server"
wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C /
