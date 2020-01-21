# Kubernetes On Desktop

Project duration: 6 person weeks

Developer: **Simone Magnani**

Tutor: **Fulvio Risso** - **Alex Palesandro**

Version: 0.1

## Description

Cloud Computing course project with the aim of developing a cloud infrastructure to run user application in a remote cluster.

Thanks to the Netgroup Polito cluster, we have developed a very high performing infrastructure to let correctly configured users deploy applications and connect to them both via vnc connection and browser.

To make modifications persistent, we decided to create a PersistentVolumeClaim that the user uses as his *HOME* directory. Few improvements will be done to make all supported application choose that directory automatically by every file manager.

Despite needing a Desktop Environment/Window Manager to run, all connections to the created deployment refer to a single application. Thus, it is not possible to perform any different operation different. The execution unit will be destroyed together with all the deployments once the user has finished to use it.

Interestingly, depending on the connection quality and on the pod availability, the required application will be executed in Cloud or in the local user computer. This is a user-friendly feature not to alter the normal execution behaviour in certain particular cases.

## Technologies used

As you can see in the Acknowledgment section, we have reused some Docker images already developed by `jlesage`. Since they are composed by the same technologies we would like to use for our own images, we gently used them, in particular for firefox and baseimage-gui to develop all the other applications.

In general, the software is composed by:

* S6-overlay, a process supervisor for containers.
* x11vnc, a X11 VNC server.
*	xvfb, a X virtual framebuffer display server.
*	openbox, a windows manager.
*	noVNC, a HTML5 VNC client.
*	NGINX, a high-performance HTTP server.
*	stunnel, a proxy encrypting arbitrary TCP connections with SSL/TLS.
*	Useful tools to ease container building.
*	Environment to better support dockerized applications.

These not only allows our infrastructure to be reachable both via a VNC client and browser, but they also ensure that everything fits user needs and tastes.

## Dependencies

* Kubernetes, more in detail `kubectl`
* Netcat
* iPerf

While Kubectl is mandatory, Netcat can be replaced by other network software to check port availability. It is used by the script used to start the application to check that the remote node is correctly started. If you prefer using a different software, modify the appositely line in the `run_cloud.sh` where `nc` is used.

Finally, to perform network measurement we used iPerf, an optimized software to accomplish our goal. The same principle described before for Netcat can be reused for iPerf, meaning that if you want to use a different software you can, but the script has to be accordingly modified.

## Supported Applications

This is the first version of the project, so we preferred to focus on the quality of our services instead than the quality.

The supported ones are:

* Firefox
* Libreoffice

## Usage

Once all the dependencies are installed, since it is a cloud based application you don't have to install anything else.

The user must use the `run_cloud.sh` script to launch application. It is strongly suggested that he has a local installation of that application, since the script will automatically launch it if there are some connection or cluster availability errors.

To use it, type in a terminal:

```bash
user@hostname:~/WorkingDirectory$ ./run_cloud.sh firefox
```

Actually there are a lot of optional parameter as reported in the script usage:

```bash
Run application in Cloud using Kubernetes as orchestrator.
Usage: ./run_cloud.sh [-h] [-i] [-e] [-d screen_resolution] [-t timeout] <application_name>
|-> -h: start the helper menu
|-> -i: start the script in interactive mode (default non-interactive)
|-> -e: specify that the connection must be encrypted (default 0)
|-> -d: specify the resolution to be used (default actual screen dimensions)
|-> -t: connection/wait timeout in seconds (default 60s)
|-> -p: connection protocol to be used (default vnc, supports also xrdp and novnc)
|
|->Example: ./run_cloud.sh firefox
|->Example: ./run_cloud.sh -d 1920x1080 -t 10 -e firefox
```

If not specified, the default ones are the following:
	
* No encryption is used
* Timeout = 60 seconds
* Screen resolution = your actual screen one
* Protocol = VNC
* Non-interactive mode

Firefox over Vnc

![Firefox over Vnc](res/Firefox.png)

Firefox over Http

![Firefox over Http](res/Firefox2.png)

## Known issues/lacks

Due to the amount of time spent digging all the different technologies, the VNC version all the docker images doesn't support the audio streaming yet. In spite performing audio redirection using PulseAudio seems to be a very efficient and easy solution, installing all the needed packages from scratch on a docker is trickier than I thought. It requires analysis and PulseAudio knowledge.

## Audio streaming version

To allow audio streaming and expose this demo, I used RDP (Remote Desktop Connection), a protocol developed by Microsoft which allows not only to see the remote desktop as VNC does, but it also redirect the audio, accomplishing our objective. In fact, an RDP connections allows you to decide whether the audio should be played locally (on the client computer via redirection) or remotely (on the server, using its audio device! In order to hear that you should physically be in the same place).

This demo shows the Firefox use case.

```bash

```

## Acknowledgments

Professor Risso

* <https://github.com/frisso>

PhD Alex Palesandro

* <https://github.com/palexster>

jlesage

* <https://hub.docker.com/r/jlesage/baseimage-gui>
* <https://hub.docker.com/r/jlesage/firefox>
* <https://github.com/jlesage/docker-baseimage-gui>
* <https://github.com/jlesage/docker-firefox>

## Other pointers

* <https://hub.docker.com/r/selenium/standalone-firefox>
* <https://github.com/SeleniumHQ/docker-selenium>
* <https://github.com/kubernetes/examples/blob/master/staging/selenium/selenium-node-firefox-deployment.yaml>
* <https://github.com/rook/rook/blob/master/cluster/examples/kubernetes/wordpress.yaml>
* <https://tnichols.org/2015/10/19/Hooking-the-Linux-System-Call-Table/>
* <https://kubernetes.io/docs/concepts/>
* <https://medium.com/@SaravSun/running-gui-applications-inside-docker-containers-83d65c0db110>
* <https://stackoverflow.com/questions/56398680/is-it-possible-to-deploy-a-gui-application-using-kubernetes>
* <https://stackoverflow.com/questions/16296753/can-you-run-gui-applications-in-a-docker-container/43082473#43082473>
* <https://xpra.org/trac/wiki/Usage>
* <https://askubuntu.com/questions/203173/run-application-on-local-machine-and-show-gui-on-remote-display>
* <https://blog.yadutaf.fr/2017/09/10/running-a-graphical-app-in-a-docker-container-on-a-remote-server/>
* <https://github.com/atlassian/docker-chromium-xvfb/blob/master/images/base/xvfb-chromium>
* <https://wiki.archlinux.org/index.php/TigerVNC>
* <https://cweiske.de/tagebuch/running-apps-high-resolution.htm>
* <https://www.cyberciti.biz/faq/install-and-configure-tigervnc-server-on-ubuntu-18-04/>
* <https://github.com/ConSol/docker-headless-vnc-container/blob/master/src/ubuntu/install/tigervnc.sh>
* <https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml>
* <https://en.wikipedia.org/wiki/X11vnc>
