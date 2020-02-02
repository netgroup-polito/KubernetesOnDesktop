#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export HOME=/config
mkdir -p /config/.libreoffice/user
#Remove previous libreoffice instance lock
rm -f /config/.config/libreoffice/*/.lock
libreoffice --version
exec /usr/bin/libreoffice_wrapper >> /config/log/libreoffice/output.log 2>> /config/log/libreoffice/error.log
