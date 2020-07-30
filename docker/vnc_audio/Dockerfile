# This Dockerfile is used to build an headles vnc image based on Ubuntu

FROM ubuntu:18.04

MAINTAINER Simone Magnani "simonemagnani.96@gmail.com"
ENV REFRESHED_AT 2020-01-29

LABEL io.k8s.description="Headless VNC Container with Xfce window manager and many applications" \
      io.k8s.display-name="Headless VNC Container based on Ubuntu"

### Application we want to install (passed as argument from build.sh)
ARG APPLICATION=unknown

### Connection ports
# VNC port:5900
# noVNC port:5800
# ssh port:22
ENV DISPLAY=:0 \
    VNC_PORT=5900 \
    NO_VNC_PORT=5800 \
    SSH_PORT=22
EXPOSE $VNC_PORT $NO_VNC_PORT $SSH_PORT

### Envrionment config
ENV HOME=/home/vncuser \
	USER=vncuser \
    APPLICATION=$APPLICATION \
    ROOT_WORKDIR=/opt/config \
    NO_VNC_HOME=/ \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=1024 \
    VNC_PASSWORD=vncpassword \
    VNC_VIEW_ONLY=false \
    SECURE_CONNECTION=0
WORKDIR $ROOT_WORKDIR

### Installing used softwares
RUN apt-get update && \
    apt-get install -y wget\
                    openbox \
                    openssh-server \
                    locales \
                    x11-xkb-utils \
                    net-tools \
                    pulseaudio \
                    python-numpy \
                    $APPLICATION && \
    apt -y autoclean

### Installing TigerVNC
RUN wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME

### Installing noVNC
RUN mkdir -p $NO_VNC_HOME/utils/websockify && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME &&\
    # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
    wget -qO- https://github.com/novnc/websockify/archive/v0.6.1.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify &&\
    chmod +x -v $NO_VNC_HOME/utils/*.sh && \
    ## create index.html to forward automatically to `vnc_lite.html`
    ln -s $NO_VNC_HOME/vnc_lite.html $NO_VNC_HOME/index.html

### To be used in case last APPLICATION release is broken, with -m in build.sh
#APPLICATION_PLACEHOLDER

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Creating User for the docker environment
RUN useradd -ms /bin/bash $USER

### Copying files and set correct permissions
ADD config /opt/config
RUN chmod +x /opt/config/*.sh

### Overwrite OpenBox config
RUN rm -rf /etc/xdg/openbox && \
    cp -R openbox /etc/xdg/openbox && \
    mv /etc/xdg/openbox/${APPLICATION}.xml /etc/xdg/openbox/rc.xml

CMD "/opt/config/docker-entrypoint.sh"
