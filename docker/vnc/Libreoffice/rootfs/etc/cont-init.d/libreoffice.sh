#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

# Make sure some directories are created.
mkdir -p /config/downloads
mkdir -p /config/log/libreoffice

# Generate machine id.
if [ ! -f /etc/machine-id ]; then
    log "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id
fi

# Verify the size of /dev/shm.
SHM_SIZE_MB="$(df -m /dev/shm | tail -n 1 | tr -s ' ' | cut -d ' ' -f2)"
if [ "$SHM_SIZE_MB" -eq 64 ]; then
   echo 'FAIL' > /config/log/libreoffice/libreoffice_shm_check
else
   echo 'PASS' > /config/log/libreoffice/libreoffice_shm_check
fi

# Make sure monitored log files exist.
for LOG_FILE in /config/log/libreoffice/error.log
do
    touch "$LOG_FILE"
done

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :
