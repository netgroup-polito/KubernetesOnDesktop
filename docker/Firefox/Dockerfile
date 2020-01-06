# Pull base image.
FROM jlesage/firefox

#Install libreoffice
RUN add-pkg pulseaudio pulseaudio-zeroconf gstreamer

# Copy the start script.
COPY startapp.sh /startapp.sh

# Set the name of the application.
ENV APP_NAME="Firefox"