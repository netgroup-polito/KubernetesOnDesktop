#!/bin/bash

#Start the docker in background
docker run firefox-vnc &

#Wait for docker to start up
sleep 2

#Start the vnc connections to the docker
vncviewer 172.17.0.2 -passwd <(echo default | vncpasswd -f)
