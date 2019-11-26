FROM    ubuntu:latest

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

# Install vnc, xvfb in order to create a 'fake' display and libreoffice
RUN     apt-get install -y x11vnc xvfb libreoffice

# Setup a password
RUN     mkdir ~/.vnc && x11vnc -storepasswd default ~/.vnc/passwd

ADD 		entrypoint.sh /usr/bin/entrypoint.sh

EXPOSE 	5900

CMD 		["/usr/bin/entrypoint.sh"]