# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9-v3.5.2

# Define working directory.
WORKDIR /tmp

# Define mountable directories.
VOLUME ["/config", "/dev/shm"]

# Install Libreoffice.
RUN apk --no-cache add libreoffice

# Install extra packages.
RUN \
    add-pkg \
        desktop-file-utils \
        adwaita-icon-theme \
        ttf-dejavu \
        ffmpeg-libs \
        # The following package is used to send key presses to the X process.
        xdotool

# Enable log monitoring.
RUN \
    add-pkg yad && \
    sed-patch 's|LOG_FILES=|LOG_FILES=/config/log/libreoffice/error.log|' /etc/logmonitor/logmonitor.conf && \
    sed-patch 's|STATUS_FILES=|STATUS_FILES=/config/log/libreoffice/libreoffice_shm_check|' /etc/logmonitor/logmonitor.conf

# Adjust the openbox config.
RUN \
    # Maximize only the main window.
    sed-patch 's/<application type="normal">/<application type="normal" title="LibreOffice">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="LibreOffice">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="Libreoffice"