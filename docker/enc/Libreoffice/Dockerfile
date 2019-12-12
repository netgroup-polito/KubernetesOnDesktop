FROM ubuntu:16.04

#Update the system and install locale
RUN apt-get clean && apt-get update && apt-get install -y locales

# Set the locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

#Set timezone
ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install vnc, xvfb in order to create a 'fake' display and firefox
RUN apt-get install --fix-missing -y x11vnc xvfb libreoffice openssh-server

RUN mkdir /var/run/sshd
RUN echo 'root:default' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

ADD 		entrypoint.sh /usr/bin/entrypoint.sh

EXPOSE 22
CMD 		["/usr/bin/entrypoint.sh"]