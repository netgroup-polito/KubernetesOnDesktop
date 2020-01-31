# This Dockerfile is used to build an headles vnc image based on Ubuntu

FROM ubuntu:16.04

MAINTAINER Simone Magnani "simonemagnani.96@gmail.com"
ENV REFRESHED_AT 2020-01-29

LABEL io.k8s.description="Headless VNC Container with Xfce window manager and many applications" \
      io.k8s.display-name="Headless VNC Container based on Ubuntu"

### Create the user
RUN useradd -ms /bin/bash default

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
# ssh port:22
ENV DISPLAY=:0 \
    VNC_PORT=5900 \
    NO_VNC_PORT=5800 \
    SSH_PORT=22
EXPOSE $VNC_PORT $NO_VNC_PORT $SSH_PORT

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=1024 \
    VNC_PASSWORD=vncpassword \
    VNC_VIEW_ONLY=false \
    BROWSER=/usr/bin/firefox \
    SECURE_CONNECTION=0
WORKDIR $HOME

### Add all install scripts
ADD ./src/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install custom fonts
RUN $INST_SCRIPTS/install_custom_fonts.sh

### Install xvnc-server, noVNC - HTML5 based VNC viewer, SSH
RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install firefox browser
RUN $INST_SCRIPTS/firefox.sh

### Install libreoffice 
RUN $INST_SCRIPTS/libreoffice.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/xfce/ $HOME/

### Install ssh server
RUN $INST_SCRIPTS/ssh.sh

### Clear unused packages
RUN $INST_SCRIPTS/clear.sh

### configure startup
ADD ./src/scripts $STARTUPDIR

### Make scripts runnable
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME


VOLUME ["/headless/mountable"]

ENTRYPOINT ["/dockerstartup/startup.sh"]
CMD ["--wait"]