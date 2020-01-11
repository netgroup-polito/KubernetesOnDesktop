## docker

In this section there are all the docker imaged developed.

More in detail:

* old: old and not performant version of docker images
	* clear: images for a non-encrypted connection
	* enc: images for an encrypted connection
	* sshXForwarding: an experiment to see how ssh X session forwarding words (efficient, easier to setup but too slow due to entire session, even if faked, forwarding)
* Firefox: the actual used Firefox image
* Libreoffice: the actual used Libreoffice image

**NB**

Both the Firefox and Libreoffice images refer to `jlesage` base-gui docker image, which not only is very performing, but also well structured and organized. They are built on Alpine linux which is known to be lightweight and very secure, even though configuration can be not so intuitive for non-Alpine users. 
Concerning the Firefox docker, I am trying to install also a pulseaudio suite to stream audio via tcp, this way the client can attach himself to that socket and reproduce audio using its own physical device. Unfortunately, since it requires time to dig deep all the modules to make audio streaming work, this features is not enabled yet.
