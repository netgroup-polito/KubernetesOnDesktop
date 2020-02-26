#!/bin/bash

# Start Xvfb
Xvfb :0 -ac -screen 0 1920x1200x24 -nolisten tcp &

#Export display env variable
export DISPLAY=:0

#Start libreoffice in background
firefox --no-sandbox &

#Start vnc server in background
x11vnc -usepw -once &

#Wait for the first background process to terminate
wait -n

#Kill all the remaining background child processes
pkill -P $$
