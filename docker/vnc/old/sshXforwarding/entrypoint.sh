#!/bin/bash

/etc/init.d/dbus start &
/etc/init.d/avahi-daemon start &

dbus-launch
pulseaudio --start

/usr/sbin/sshd -D &

#Wait for the first background process to terminate
wait -n

#Kill all the remaining background child processes
pkill -P $$