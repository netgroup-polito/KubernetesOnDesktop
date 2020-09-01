## docker

In this section there are the official Dockerfiles, supporting both video and audio features, used to manage both the vnc server side, wich also run the required application (e.g. Firefox), and the vnc client side that shows the server app GUI. This main section it's splitted in two more sections called "vncserver" and "vncviewer".

### The vncserver section
The "vncserver" section contains two more sub-sections:
1. a `base_image` sub-section that contains a Dockerfile to create an image with all the required audio/video streaming packages. This Dockerfile has a `FROM_IMAGE` build argument that let you choose which image you want to use as *Parent Image*. This way it is possible to use a NVIDIA *Parent Image* (`nvidia/cuda:10.2-runtime-ubuntu18.04`), instead of the default one (`ubuntu:18.04`), to make it possible to let the application use a NVIDIA CUDA graphic card (so far just `blender` is supported as application using NVIDIA CUDA graphic card).

2. an `app_image` sub-section, that contains a Dockerfile created by using the `base_image` specified above as *Parent Image*, to create an image that has both a VNC and a noVNC protocol servers. Also, this Dockerfile has the following build arguments:
    * a `FROM_IMAGE` that let you choose which image you want to use as *Parent Image*. This way it is possible to choose a *Parent Image* with NVIDIA CUDA support (as specified above) and run the application by using the NVIDIA CUDA graphic card;
    * an `APPLICATION` that let you specify which GUI application you want to install and run inside the docker. So far, just the following application are supported: firefox, libreoffice, blender.
    * a `REPO_TO_ADD` that let you specify which required apt repository to add (if any). This is useful in case the application apt package is not in the canonical repository. E.g., the blender package is not stored in the canonical repository so it is required to add the `ppa:thomas-schiex/blender` repository to install the application.

### The vncviewer section
The vncviewer section contains the Dockerfile to create a vncviewer image that supports VNC protocol and works with all the application above. It also supports the audio streaming (through SSH protocol) by running a PulseAudio server, resulting in a complete and enjoyable user experience.
Finally, thanks to the insense use of templates, the image can be used both as a container running on the local machine or as a container running in a Kubernetes pod.

### The `build_image.sh` application
Thanks to an intense use of templates, each image can be easily built using the `build_image.sh` script as described in its help shown by running `build_image.sh -h`. Command output below:

```
Builds specified image and pushes it in DokerHub.
Usage: ./build_image.sh [-h] [-r] [-v <build version>] [-p <push version>] -i <image>
|-> -h: start the helper menu
|-> -r: rebuild image by removing the existing one (if any) and building it again
|-> -v: specify the version to build. If not set, 'latest' will be used
|-> -p: push the -v specified image version on DockerHub. It is possible to specify more than one version, one for each -p option.
|       In any cases, the built image will be tagged with that versions and pushed on DockerHub
|-> -i: (MANDATORY) the image to build. Supported images: vncviewer,base,firefox,libreoffice,blender,cuda-base,cuda-blender
|
|->Example: ./build_image.sh -i firefox
|->Example: ./build_image.sh -v v1.0 -i base
|->Example: ./build_image.sh -v v2.0 -p v2.0 -p stable -p latest -i vncviewer
|           in this case the image with version v2.0 will be tagged with 'stable' and 'latest' versions and all that three tags
|           will be pushed on DockerHub
```
