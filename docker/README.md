## docker

In this section there is the official image used supporting also the audio feature. It has been built with both VNC and noVNC protocols and it supports the following applications:

* Firefox
* Libreoffice

Thanks to an intense use of templates, the image has many parameters tunable and modifiable "a posteriori", meaning that all the startup scripts will read those parameters at run time, letting the user modify them using the cloudify script.

This image contains a complete Ubuntu 16.04 installation and the supported softwares. Even though most of the default packages are not useful in our scenario, I opted for installing the entire environment, because this way many features we would like to insert are already managed, like the audio. Moreover, I thought it could be useful to give the user a minimal environment with softwares like a File Manager, to manage its file and configuration, of course without root privileges. In fact, even though the docker starts as root to run many services like ssh server, the session is immediately switched to an unprivileged execution, to avoid that all incoming vnc/ssh connections damage it.

A special thanks goes to [consol](https://github.com/ConSol/docker-headless-vnc-container), which was a very inspiring project for the structure of mine.