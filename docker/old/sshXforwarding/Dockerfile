FROM ubuntu:latest

MAINTAINER Simone Magnani, simonemagnani.96@gmail.com

# Tell debconf to run in non-interactive mode
ENV DEBIAN_FRONTEND noninteractive

#Update the system and install locale
RUN apt-get update \
		&& apt-get install -y locales

# Set the locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#Set timezone
ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
		&& echo $TZ > /etc/timezone

RUN apt install -y firefox \
    									dbus \
    									dbus-x11 \
    									pulseaudio \
                      openssh-server \
                      xauth \
    && mkdir /var/run/sshd \
    && mkdir /root/.ssh \
    && chmod 700 /root/.ssh \
    && ssh-keygen -A \
    && sed -i "s/^.*PasswordAuthentication.*$/PasswordAuthentication no/" /etc/ssh/sshd_config \
    && sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config \
    && sed -i "s/^.*X11UseLocalhost.*$/X11UseLocalhost no/" /etc/ssh/sshd_config \
    && grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config

ADD id_rsa.pub /root/.ssh/authorized_keys
ADD entrypoint.sh /usr/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

EXPOSE 22
