#============================#
# Information & Requirements #
#============================#
# This Dockerfile is used to build an headles vnc image based on Ubuntu
# It starts from a previous work by Simone Magnani <simonemagnani.96@gmail.com>
#
# *** Build the docker ***
#
# Default build
# docker build --build-arg APPLICATION=<app_name> [--build-arg REPO_TO_ADD=<repo>] [--build-arg FROM_IMAGE=<base image>] -t riccardoroccaro/<app_name>-headless-vnc:stable .
#
# Build with NVIDIA support => so far, used when APPLICATION=blender
# docker build --build-arg APPLICATION=blender --build-arg REPO_TO_ADD="ppa:thomas-schiex/blender" --build-arg FROM_IMAGE="riccardoroccaro/cuda-base-headless-vnc:stable" -t riccardoroccaro/cuda-blender-headless-vnc:stable .
#


### Build argument that specifies which base image to start from.
ARG FROM_IMAGE="riccardoroccaro/base-headless-vnc:stable"

FROM ${FROM_IMAGE}
LABEL maintainer="Riccardo Roccaro <r0cc4rd0@gmail.com>"
ENV REFRESHED_AT 2020-08-25
SHELL ["/bin/bash", "-c"]

### Application we want to install (passed as --build-arg from build_image.sh)
ARG APPLICATION=unknown

### Required repository to install the application we want (passed as --build-arg from build_image.sh)
ARG REPO_TO_ADD=unknown

### Environment config
ENV APPLICATION=$APPLICATION

### Selecting workdir
WORKDIR $ROOT_WORKDIR

### Adding required repository (if needed)
RUN if [[ ${REPO_TO_ADD} != "unknown" ]]; then \
        apt-get update && \
        apt-get install -y software-properties-common && \
        add-apt-repository ${REPO_TO_ADD}; \
    fi

### Installing used software.
RUN apt-get update
RUN apt-get install -y $APPLICATION

### Cleaning up
RUN if [[ ${REPO_TO_ADD} != "unknown" ]]; then \
        apt-get purge -y software-properties-common; \
    fi
RUN apt-get --purge autoremove -y && \
    apt-get autoclean -y && \
    rm /etc/apt/sources.list && \
    rm -rf /var/cache/apt/archives/* && \
    rm -rf /var/lib/apt/lists/*

### Copying files and giving them required privileges
ADD config /opt/config
RUN chmod -R 777 /opt/config/*

### Overwriting OpenBox config
RUN rm -rf /etc/xdg/openbox && \
    cp -R openbox /etc/xdg/openbox && \
    mv /etc/xdg/openbox/${APPLICATION}.xml /etc/xdg/openbox/rc.xml

### Creating ssh_secret dir inside user's home to mount the secret
RUN mkdir ${HOME}/ssh_secret && \
    chmod 775 ${HOME}/ssh_secret

### Setting entrypoint
ENTRYPOINT [ "/opt/config/docker-entrypoint.sh" ] 
