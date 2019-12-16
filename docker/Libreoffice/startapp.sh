#!/bin/sh

#Creating the user home directory
mkdir /config/shared_volume
#Export home
export HOME=/config/shared_volume
#Remove previous libreoffice instance lock
rm -f /config/shared_volume/.config/libreoffice/*/.lock
#Exec libreoffice
exec /usr/bin/libreoffice