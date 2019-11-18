FROM    ubuntu:latest

# Install vnc, xvfb in order to create a 'fake' display and firefox
RUN     apt-get update && apt-get install -y x11vnc xvfb firefox

# Setup a password
RUN     mkdir ~/.vnc && x11vnc -storepasswd default ~/.vnc/passwd

ADD 		entrypoint.sh /usr/bin/entrypoint.sh

EXPOSE 	5900

CMD 		["/usr/bin/entrypoint.sh"]
