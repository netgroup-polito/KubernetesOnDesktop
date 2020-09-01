#============================#
# Information & Requirements #
#============================#
# *** Build tigervnc docker ***
#
# docker build -t liqo/vncviewer:latest .
#
# *** Run vncviewer in a container ***
#
# docker run --name vncviewer \
#     -v ${working_dir}:/home/vnc/ssh_id_rsa \
#     -v /tmp/.X11-unix/:/tmp/.X11-unix/ \
#     --device /dev/snd \
#     -v /dev/shm:/dev/shm \
#     -v /var/run/dbus:/var/run/dbus \
#     -e DISPLAY \
#     liqo/vncviewer:latest \
#     enc=<enc> `#enc [1|0]` \
#     pod=<pod> `#pod [1|0]` \
#     compression=<CompressLevel> `#comression [0-6]` \
#     quality=<QualityLevel> `#quality [0-9]` \
#     target=<target_IP::port> `#target` \
#     token=<token (passwd)> `#token` \
#     target_node_ip=<targetNodeIp> `#targetNodeIp` \
#     target_node_port_ssh=<targetNodePortSsh> `#targetNodePortSsh` \
#     enc_port=<port> `#enc_port` \
#     client_host_ip=<clientHostIP> `#clientHostIP` \
#     client_host_port=<clientHostPort> `#clientHostPort`
#
# Usage: enc, pod, compression, quality, target, token,arget_node_ip and target_node_port_ssh params are MANDATORY IN ANY CASE
#        enc_port param is REQUIRED ONLY IF enc=1
#        client_host_ip and client_host_port params are REQUIRED ONLY IF pod=1
#
# N.B.: in case you want to use the docker in kubernetes, due to `--device` unsupported feature, you need
# to mount the `/dev/snd` volume by using:
#
# ...
# ...
# containers:
# - name: foo
#   volumeMounts:
#   - mountPath: /dev/snd
#     name: dev-snd
#   securityContext:
#     privileged: true
# volumes:
# - name: dev-snd
#   hostPath:
#     path: /dev/snd
# ...
# ...
#
# which is the same as doing the `docker run` by replaceing the line:
# `--device /dev/snd`
# with:
# `-v /dev/snd:/dev/snd`
# and adding before the image name (liqo/vncviewer:latest) line the following:
# `--privileged`
#

FROM ubuntu:focal
LABEL maintainer="Riccardo Roccaro <r0cc4rd0@gmail.com>"
ENV REFRESHED_AT 2020-07-26 
SHELL ["/bin/bash", "-c"]

# VARIABLES
ENV USER=vnc \
    ROOT_PATH=/ \
    PULSE_PORT=34567

#===============================================#
# Install audio, video and general dependencies #
#===============================================#
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    ssh \
    netcat \
    pulseaudio \
    libgl1-mesa-dri \
    libgl1-mesa-glx

#==================#
# Install tigervnc #
#==================#
RUN wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C /

#=====================#
# VNC: Dedicated User #
#=====================#
ENV HOME /home/${USER}
RUN echo ${HOME} && echo ${USER}
RUN useradd -d ${HOME} -m ${USER} && \
    passwd -d ${USER} && \
    usermod -aG audio ${USER}

#==========#
# Clean up #
#==========#
RUN apt-get purge wget -y && \
    apt-get --purge autoremove -y && \
    apt-get autoclean -y && \
    rm /etc/apt/sources.list && \
    rm -rf /var/cache/apt/archives/* && \
    rm -rf /var/lib/apt/lists/*

#=================================#
# COPYING PULSEAUDIO CONFIG FILES #
#=================================#
COPY [ "./resources/pulseaudio_config/client.conf", "./resources/pulseaudio_config/daemon.conf", "./resources/pulseaudio_config/default.pa", "/etc/pulse/" ]
COPY [ "./resources/pulseaudio_config/avahi-daemon.conf", "/etc/avahi/" ]
RUN chmod 777 /etc/pulse/*

#===============================#
# COPYING EXECUTABLE ENTRYPOINT #
#===============================#
COPY ./resources/run_vncviewer.sh ${HOME}
RUN chmod 777 ${HOME}/run_vncviewer.sh

#================#
# USER SELECTION #
#================#
USER ${USER}

#===================#
# STORAGE SELECTION #
#===================#
WORKDIR ${HOME}

#==============================================#
# CREATING SSH IDENTITY AND SOCKET DIRECTORIES #
#==============================================#
RUN mkdir ${HOME}/ssh_id_rsa
ENV SSH_ID_RSA=${HOME}/ssh_id_rsa
RUN mkdir ${HOME}/ssh_socket
ENV SSH_SOCKET=${HOME}/ssh_socket

#====================#
# SETTING ENTRYPOINT #
#====================#
ENTRYPOINT [ "./run_vncviewer.sh" ]
