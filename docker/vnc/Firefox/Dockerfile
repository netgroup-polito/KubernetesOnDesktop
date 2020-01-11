# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9-v3.5.2

# Define software versions.
ARG JSONLZ4_VERSION=c4305b8
ARG LZ4_VERSION=1.8.1.2

# Define software download URLs.
ARG JSONLZ4_URL=https://github.com/avih/dejsonlz4/archive/${JSONLZ4_VERSION}.tar.gz
ARG LZ4_URL=https://github.com/lz4/lz4/archive/v${LZ4_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Define mountable directories.
VOLUME ["/config", "/dev/shm"]

# Install Firefox.
RUN apk --no-cache add firefox-esr

# Install extra packages.
RUN \
    add-pkg \
        desktop-file-utils \
        adwaita-icon-theme \
        ttf-dejavu \
        ffmpeg-libs \
        # The following package is used to send key presses to the X process.
        xdotool

# Set default settings.
RUN \
    CFG_FILE="$(ls /usr/lib/firefox/browser/defaults/preferences/firefox-branding.js)" && \
    echo '' >> "$CFG_FILE" && \
    echo '// Default download directory.' >> "$CFG_FILE" && \
    echo "pref(\"browser.download.dir\", \"/config\");" >> "$CFG_FILE" && \
    echo 'pref("browser.download.folderList", 2);' >> "$CFG_FILE"

# Install JSONLZ4 tools.
# Essential if you want Firefox persistency
RUN \
    add-pkg --virtual build-dependencies \
        curl \
        build-base \
        && \
    mkdir jsonlz4 && \
    mkdir lz4 && \
    curl -# -L {$JSONLZ4_URL} | tar xz --strip 1 -C jsonlz4 && \
    curl -# -L {$LZ4_URL} | tar xz --strip 1 -C lz4 && \
    mv jsonlz4/src/ref_compress/*.c jsonlz4/src/ && \
    cp lz4/lib/lz4.* jsonlz4/src/ && \
    cd jsonlz4 && \
    gcc -Wall -o dejsonlz4 src/dejsonlz4.c src/lz4.c && \
    gcc -Wall -o jsonlz4 src/jsonlz4.c src/lz4.c && \
    strip dejsonlz4 jsonlz4 && \
    cp -v dejsonlz4 /usr/bin/ && \
    cp -v jsonlz4 /usr/bin/ && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Enable log monitoring.
RUN \
    add-pkg yad && \
    sed-patch 's|LOG_FILES=|LOG_FILES=/config/log/firefox/error.log|' /etc/logmonitor/logmonitor.conf && \
    sed-patch 's|STATUS_FILES=|STATUS_FILES=/config/log/firefox/firefox_shm_check|' /etc/logmonitor/logmonitor.conf

# Adjust the openbox config.
RUN \
    # Maximize only the main window.
    sed-patch 's/<application type="normal">/<application type="normal" title="Mozilla Firefox">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="Mozilla Firefox">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="Firefox"