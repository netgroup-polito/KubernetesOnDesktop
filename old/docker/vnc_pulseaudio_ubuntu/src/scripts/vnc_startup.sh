#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

## correct forwarding of shutdown signal
cleanup () {
    kill -s SIGTERM $!
    exit 0
}
trap cleanup SIGINT SIGTERM

## resolve_vnc_connection
VNC_IP=$(hostname -i)

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

## start vncserver and noVNC webclient
$NO_VNC_HOME/utils/launch.sh --vnc localhost:$VNC_PORT --listen $NO_VNC_PORT &> $STARTUPDIR/no_vnc_startup.log &

vncserver -kill $DISPLAY &> $STARTUPDIR/vnc_startup.log \
    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix &> $STARTUPDIR/vnc_startup.log

if [[ $SECURE_CONNECTION -eq 0 ]]; then
	vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} &> $STARTUPDIR/no_vnc_startup.log
else
	vncserver $DISPLAY -localhost -depth $VNC_COL_DEPTH -geometry ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} &> $STARTUPDIR/no_vnc_startup.log
fi
PID_SUB=$!

$HOME/wm_startup.sh &> $STARTUPDIR/wm_startup.log

if [ -z "$1" ] || [[ $1 =~ -w|--wait ]]; then
    wait $PID_SUB
fi
