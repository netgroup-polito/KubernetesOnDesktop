FROM danielguerra/dockergui

# User/Group Id 
ENV USER_ID=1000
ENV GROUP_ID=1000

# Define mountable directories.
VOLUME ["/config", "/dev/shm"]

# Gui App Name
ENV APP_NAME Firefox

# Default resolution
ENV WIDTH=1280
ENV HEIGHT=720

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

RUN add-apt-repository ppa:nilarimogard/webupd8
RUN apt-get update

ENV DEBIAN_FRONTEND noninteractive

# Install steps for X app
RUN apt-get -yy install browser-plugin-freshplayer-pepperflash firefox

RUN apt-get -yy install mplayer gstreamer0.10-pulseaudio pulseaudio-equalizer && \
    rm -rf /var/cache/apk/*

# Set to start firefox
RUN sed -i -e 's/\/usr\/bin\/openbox-session/dbus-launch \/usr\/bin\/firefox/' /etc/service/openbox/run
