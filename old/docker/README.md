## docker

In this section there are all the old docker imaged developed.

More in detail:


* clear: images for a non-encrypted connection (1st version, not usable at all)
* enc: images for an encrypted connection (1st version, not usable at all)
* sshXForwarding: an experiment to see how ssh X session forwarding words (efficient on LAN, easier to setup but too slow due to entire session, even if faked, forwarding)
* xrdp: ubuntu image supporting the audio and video streaming via RDP protocol (efficient only LAN)
* vnc: official images supported and developed for the 1st version of the project

**NB**

Both the `vnc/Firefox` and `vncLibreoffice` official images refer to `jlesage` [base-gui docker image](https://hub.docker.com/r/jlesage/baseimage-gui), which not only is very performing, but also well structured and organized. They are built on Alpine linux which is known to be lightweight and very secure, even though configuration can be not so intuitive for non-Alpine users. 
