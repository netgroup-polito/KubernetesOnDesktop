## docker

In this section there are the official Dockerfiles, supporting also the audio feature, used to manage both the vnc server side, wich also run the required application (e.g. Firefox), and the vnc client side that shows the server app GUI. This main section it's splitted in two more sections called "vncserver" and "vncviewer".

### The vncserver section
The "vncserver" section contains two more sub-sections:
1. a `base_image` sub-section that contains a Dockerfile to create an image with all the required audio/video streaming packages. This Dockerfile has a `FROM_IMAGE` build argument that let you choose which image you want to use as *Parent Image*. This way it is possible to use a NVIDIA *Parent Image* (`nvidia/cuda:10.2-runtime-ubuntu18.04`), instead of the default one (`ubuntu:18.04`), to make it possible to let the application use a NVIDIA CUDA graphic card (so far just `blender` is supported as application).

2. an `app_image` sub-section, that contains a Dockerfile created by using the `base_image` specified above as *Parent Image*, to create an image that has both a VNC and a noVNC protocol servers. Also this Dockerfile has:
* a `FROM_IMAGE` build argument that let you choose which image you want to use as *Parent Image*. This way it is possible to choose a *Parent Image* with NVIDIA CUDA support (as specified above) and run the application by using the NVIDIA CUDA graphic card;
* an `APPLICATION` build argument that let you specify which GUI application you want to install and run inside the docker. So far, just the following application are supported: firefox, libreoffice, blender.
* a `REPO_TO_ADD` build argument that let you specify which required apt repository to add (if any). This is useful in case the application apt package is not in the canonical repository. E.g., blender haven't its package in the canonical repository so it is required to add the `ppa:thomas-schiex/blender` repository to install the application.

### The vncviewer section
The vncviewer section contains the Dockerfile to create a vncviewer image that supports VNC protocol and works with all the application above. It also supports the audio streaming (through SSH protocol) by running a PulseAudio server, resulting in a complete and enjoyable user experience.
Finally, thanks to the insense use of templates, the image can be used both as a container running on the local machine or as a container running in a Kubernetes pod.

### The `build_image.sh` application
TODO


In any case, to make it simple to recreate all the images above only if needed (e.g. when the dockerfile has been changed) it is possible to run it with the `-r` parameter. Otherwise, if an image already exists, the build process will be skipped.

Thanks to an intense use of templates, the image can be easily built using the `build_image.sh -i <app_name>` script passing as -i parameter "base", for the base image, or the name of the application we want to install inside the docker (ex. firefox, libreoffice), for the app image. This way, the resulting image is lighter than a complete Linux installation and has only the service needed by the user.
The images creating using those build configurations have both video (vnc) and audio (PulseAudio) support, resulting in a complete and enjoyable user experience.