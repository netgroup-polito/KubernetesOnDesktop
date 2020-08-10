#!/bin/bash -xe
set -e

## change vnc password
# first entry is control, second is view (if only one is valid for both)
mkdir -p "$HOME/.vnc"
PASSWD_PATH="$HOME/.vnc/passwd"

if [[ -f $PASSWD_PATH ]]; then
    rm -f $PASSWD_PATH
fi

if [[ $VNC_VIEW_ONLY == "true" ]]; then
    #create random pw to prevent access
    echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20) | vncpasswd -f > $PASSWD_PATH
fi
echo "$VNC_PASSWORD" | vncpasswd -f >> $PASSWD_PATH
chmod 600 $PASSWD_PATH

vncserver -kill $DISPLAY || rm -rfv /tmp/.X*-lock /tmp/.X11-unix

if [[ $SECURE_CONNECTION -eq 1 ]]; then
	IS_VNC_LOCALHOST="-localhost"
fi
vncserver $DISPLAY $IS_VNC_LOCALHOST -depth $VNC_COL_DEPTH -geometry ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} -noxstartup -MaxDisconnectionTime=60

$NO_VNC_HOME/utils/launch.sh --vnc localhost:$VNC_PORT --listen $NO_VNC_PORT &

openbox-session &

if [[ ! -z "$APPLICATION" ]]; then
	exec $APPLICATION &
else
	pkill -P $$
fi

#Wait for the first background process to terminate
wait -n

#Kill all the remaining background child processes
pkill -P $$