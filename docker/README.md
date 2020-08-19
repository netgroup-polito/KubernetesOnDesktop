## docker

In this section there are the official docker images, supporting also the audio feature, used to manage both the vnc server side, wich also run the required application (e.g. Firefox), and the vnc client side that shows the server app GUI. This main section it's splitted in two more sections called "vncserver" and "vncviewer".

 The "vncserver" section,
 contains a base image with all the required audio/video streaming packages and a second image template (created `from:` the first one) that has been built with both VNC and noVNC protocols and that supports the following applications:

* Firefox
* Libreoffice

Thanks to an intense use of templates, the image can be easily built using the `build_image.sh -i <app_name>` script passing as -i parameter "base", for the base image, or the name of the application we want to install inside the docker (ex. firefox, libreoffice), for the app image. This way, the resulting image is lighter than a complete Linux installation and has only the service needed by the user.
The images creating using those build configurations have both video (vnc) and audio (PulseAudio) support, resulting in a complete and enjoyable user experience.

The "vncviewer" section,
contains the vncviewer image that can be easily built using the `build_image.sh -i vncviewer` script and parameter. 

In any case, to make it simple to recreate all the images above only if needed (e.g. when the dockerfile has been changed) it is possible to run it with the `-r` parameter. Otherwise, if an image already exists, the build process will be skipped.

This image supports VNC protocol and works whith all the application above. It support both video (vnc) and audio (PulseAudio), resulting in a complete and enjoyable user experience.

Finally, thanks to the insense use of templates, the image can be used both as a container running on the local machine or as a container running in a Kubernetes pod.
