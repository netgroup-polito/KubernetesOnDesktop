#!/bin/bash

#Consts
SRC_LINE_1='RUN apt-get install -y $APPLICATION'
ESC_SRC_LINE_1=$(printf '%s\n' "$SRC_LINE_1" | sed -e 's/[]\/$*.^[]/\\&/g')

SRC_LINE_2='### APP_LINE_2'
ESC_SRC_LINE_2=$(printf '%s\n' "$SRC_LINE_2" | sed -e 's/[]\/$*.^[]/\\&/g')

SRC_LINE_3='### APP_LINE_3'
ESC_SRC_LINE_3=$(printf '%s\n' "$SRC_LINE_3" | sed -e 's/[]\/$*.^[]/\\&/g')

DST_LINE_1='RUN apt-get install -y wget && \'
ESC_DST_LINE_1=$(printf '%s\n' "$DST_LINE_1" | sed -e 's/[\/&]/\\&/g')

DST_LINE_3='apt-get purge wget -y'
ESC_DST_LINE_3=$(printf '%s\n' "$DST_LINE_3" | sed -e 's/[\/&]/\\&/g')

TEMPLATE='./app_image/Dockerfile.template'
DOCKERFILE='./app_image/Dockerfile'

V="v1.0"

function on_sigint {
	#Removing the dockerfile leaving the template
    rm -f $DOCKERFILE

    trap -- SIGINT EXIT

    exit $1
}

function main {
    #Copy the template to the Dockerfile
    cp $TEMPLATE $DOCKERFILE

    #Set trap to clean when it exits
    trap on_sigint SIGINT EXIT

    if [ "$2" = "-m" ]; then    
        #Setting the DST_LINE_2 according to the specified application
        if [ "$1" = "firefox" ]; then
            DST_LINE_2='wget -qO- https://ftp.mozilla.org/pub/firefox/releases/7.0/linux-i686/en-US/firefox-7.0.tar.bz2 | tar -xj --strip 1 -C /opt && chmod u+x /opt/*.sh && \'
            V="v1.0-m"
        elif [ $1 = "libreoffice" ]; then
            DST_LINE_2='wget -qO- http://download.documentfoundation.org/libreoffice/stable/6.0.0/deb/x86_64/LibreOffice_6.0.0_Linux_x86-64_deb.tar.gz | tar -xj --strip 1 -C /opt && cd /opt/LibreOffice_6.0.0.3_Linux_x86-64_deb/DEBS/ && sudo dpkg -i *.deb && \'
            V="v1.0-m"
        else
            echo "$1 unsupported application, exiting."
            exit 1
        fi

        ESC_DST_LINE_2=$(printf '%s\n' "$DST_LINE_2" | sed -e 's/[\/&]/\\&/g')

        #Replacing the app installing lines
        sed -i "s%$ESC_SRC_LINE_1%$ESC_DST_LINE_1%g" $DOCKERFILE
        sed -i "s%$ESC_SRC_LINE_2%$ESC_DST_LINE_2%g" $DOCKERFILE
        sed -i "s%$ESC_SRC_LINE_3%$ESC_DST_LINE_3%g" $DOCKERFILE

    fi

    # Building the base image
    docker build -t riccardoroccaro/base-headless-vnc:v1.0 ./base_image
        
    # The first argument is the name of the application we want in the docker
    docker build --build-arg APPLICATION=$1 -t riccardoroccaro/$1-headless-vnc:$V ./app_image

    exit 0
}

main $@