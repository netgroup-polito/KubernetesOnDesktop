#============================#
# Information & Requirements #
#============================#
# This Dockerfile is used to build an headles vnc image based on Ubuntu
# It starts from a previous work by Simone Magnani <simonemagnani.96@gmail.com>
#
# *** Build the docker ***
#
# docker build --build-arg APPLICATION=<app_name> -t riccardoroccaro/<app_name>-headless-vnc:stable .
#

FROM riccardoroccaro/base-headless-vnc:stable
LABEL maintainer="Riccardo Roccaro <r0cc4rd0@gmail.com>"
ENV REFRESHED_AT 2020-08-20

### Application we want to install (passed as argument from build.sh)
ARG APPLICATION=unknown

### Environment config
ENV APPLICATION=$APPLICATION

### Selecting workdir
WORKDIR $ROOT_WORKDIR

### Installing used software.
RUN apt-get update
RUN apt-get install -y $APPLICATION

### Cleaning up
RUN apt-get --purge autoremove -y && \
    apt-get autoclean -y && \
    rm /etc/apt/sources.list && \
    rm -rf /var/cache/apt/archives/* && \
    rm -rf /var/lib/apt/lists/*

### Copying files and set correct permissions
ADD config /opt/config
RUN chmod -R 777 /opt/config/*

### Overwrite OpenBox config
RUN rm -rf /etc/xdg/openbox && \
    cp -R openbox /etc/xdg/openbox && \
    mv /etc/xdg/openbox/${APPLICATION}.xml /etc/xdg/openbox/rc.xml

### Creating ssh_secret dir inside user's home to mount the secret
RUN mkdir ${HOME}/ssh_secret && \
    chmod 775 ${HOME}/ssh_secret

### Setting entrypoint
ENTRYPOINT [ "/opt/config/docker-entrypoint.sh" ] 
