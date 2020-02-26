#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

### disable screensaver and power management
xset -dpms &
xset s noblank &
xset s off &

/usr/bin/startxfce4 --replace > $HOME/wm.log &
sleep 3

if [[ ! -z "$COMMAND" ]]; then
    exec $COMMAND &
    xdotool search --sync --onlyvisible --class "$COMMAND" windowsize 100% 100%
    PID_SUB=$!
fi

