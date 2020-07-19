#!/bin/bash

function on_sigint {
	#Uncommenting placeholder and deleting application line
	sed -i "${placeholder_line_number}s/.*/$placeholder/" Dockerfile
}

placeholder="#APPLICATION_PLACEHOLDER"
placeholder_line_number=`grep -w -n "$placeholder" Dockerfile | cut -d : -f -1`

if [ "$2" = "-m" ]; then

	#TODO: need also the shared libraries
	
	if [ "$1" = "firefox" ]; then
		to_be_added="RUN wget -qO- https://ftp.mozilla.org/pub/firefox/releases/7.0/linux-i686/en-US/firefox-7.0.tar.bz2 | tar -xj --strip 1 -C /opt \&\& chmod u+x /opt/*.sh \&\& ln -s /opt/firefox /usr/bin/firefox"
	elif [ $1 = "libreoffice" ]; then
		to_be_added="RUN wget -qO- http://download.documentfoundation.org/libreoffice/stable/6.0.0/deb/x86_64/LibreOffice_6.0.0_Linux_x86-64_deb.tar.gz | tar -xj --strip 1 -C /opt \&\& cd /opt/LibreOffice_6.0.0.3_Linux_x86-64_deb/DEBS/ \&\& sudo dpkg -i *.deb"
	else
		echo "$1 unsupported application, exiting."
		exit 1
	fi
else
	to_be_added='RUN apt-get install -y $APPLICATION'
fi

sed -i "${placeholder_line_number}s^.*^$to_be_added^" Dockerfile

trap on_sigint SIGINT EXIT

# The first argument is the name of the application we want in the docker
docker build --no-cache --build-arg APPLICATION=$1 -t s41m0n/$1-headless-vnc .