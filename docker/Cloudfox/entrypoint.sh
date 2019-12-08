#!/bin/bash

# Start Xvfb
Xvfb :99 -ac -screen 0 1920x1200x24 -nolisten tcp &

#Export display env variable
export DISPLAY=:99

/usr/sbin/sshd -D &

#Start firefox in background
firefox --no-sandbox &

#Start vnc server in background
x11vnc -once -localhost &

#Wait for the first background process to terminate
wait -n

#Kill all the remaining background child processes
pkill -P $$
