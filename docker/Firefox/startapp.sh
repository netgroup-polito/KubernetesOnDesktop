#!/bin/sh

#Creating the user home directory
mkdir /config/shared_volume
#Export home
export HOME=/config/shared_volume
#Remove previous libreoffice instance lock
rm -f /config/shared_volume/.config/firefox/*/.lock
#Exec libreoffice
exec /usr/bin/firefox