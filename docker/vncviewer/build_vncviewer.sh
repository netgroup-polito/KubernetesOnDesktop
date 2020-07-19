#!/bin/bash

#Check whether the image exists or not
sudo docker inspect r0ccard0/tigervnc:v1 &>/dev/null
if [[ $? == 0 ]]; then
  echo "The image already exists"

  #Removing the image if -r option is specified
  if [[ $1 == "-r" ]]; then
    echo "Specified -r option => The image will be removed and built again"
    sudo docker image rm r0ccard0/tigervnc:v1
  else
    echo "Skip building..."
    exit 0
  fi
fi

#Building the docker image
echo "Building the docker image..."
sudo docker build -t r0ccard0/tigervnc:v1 .
echo "Done."
