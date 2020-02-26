## docker

In this section there is the official image used supporting also the audio feature. It has been built with both VNC and noVNC protocols and it supports the following applications:

* Firefox
* Libreoffice

Thanks to an intense use of templates, the image can be easily built using the `vnc_audio/build.sh <app_name>` script passing as parameter the name of the application we want to install inside the docker (ex. Firefox). This way, the resulting image is lighter than a complete Linux installation and has only the service needed by the user.

The images creating using those build configurations have both video (vnc) and audio (PulseAudio) support, resulting in a complete and enjoyable user experience.