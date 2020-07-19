#!/bin/bash

function on_sigint {
	#Uncommenting placeholder and deleting application line
	sed -i "${line_number}d" Dockerfile
}

if [ "$2" = "-m" ]; then

	if [ "$1" = "firefox" ]; then
		to_be_added="RUN wget -qO- https://ftp.mozilla.org/pub/firefox/releases/7.0/linux-i686/en-US/firefox-7.0.tar.bz2 | tar -xj --strip 1 -C /opt && chmod u+x /opt/*.sh"
	elif [ $1 = "libreoffice" ]; then
		to_be_added="RUN wget -qO- http://download.documentfoundation.org/libreoffice/stable/6.0.0/deb/x86_64/LibreOffice_6.0.0_Linux_x86-64_deb.tar.gz | tar -xj --strip 1 -C /opt && cd /opt/LibreOffice_6.0.0.3_Linux_x86-64_deb/DEBS/ && sudo dpkg -i *.deb"
	else
		echo "$1 unsupported application, exiting."
		exit 1
	fi

	placeholder_line_number=`grep -w -n 'APPLICATION_PLACEHOLDER' Dockerfile | cut -d : -f -1`
	((line_number=placeholder_line_number+1))

	#Commenting placeholder and inserting application install line
	sed -i "${line_number}i\\$to_be_added" Dockerfile

	trap on_sigint SIGINT EXIT
fi
	
# The first argument is the name of the application we want in the docker
docker build --build-arg APPLICATION=$1 -t s41m0n/$1-headless-vnc .
