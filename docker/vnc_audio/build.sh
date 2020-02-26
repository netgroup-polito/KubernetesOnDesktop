#!/bin/bash

# The first argument is the name of the application we want in the docker
docker build --build-arg APPLICATION=$1 -t s41m0n/$1-headless-vnc .