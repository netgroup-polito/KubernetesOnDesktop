## Weekly report n°3 - Kubernetes on Desktop: offloading applications to a nearby worker node

Days of interest: 11/11/19 - 15/11/19


### Objective achieved

As visible in the [Links of reference](#link-of-reference) section, this week I spent a lot of time trying to find out a feasible and optimal solution to our problem. After digging for days, I was able to create our first docker using the following technologies:

* Xvfb
* x11vnc
* firefox

There's clearly a reason why I used those ones: while firefox and x11vnc are pretty obvious (the former is the application to be tested, the latter is the vnc server for X environment), the choice of **Xvfb** is what characterize this implementation from every already existing docker/container I found.

According to the documentation:

``
Xvfb is an in-memory display server for UNIX-like operating system (e.g., Linux). It enables you to run graphical applications without a display (e.g., browser tests on a CI server) while also having the ability to take screenshots.
``

Since having a docker with a complete Desktop environment seems pretty huge to me, I decided to try this application which "emulates" it and let us run GUI application. Moreover, since the system is totally unaware of the fact that there's a virtual desktop instead of a physical one, I was able to install a vnc server which let users connect to this Xvfb desktop.

As a result, a user can double click his local application (which by now is a bash script) which is actually run in a docker environment, but he sees the output via an automated vnc connection.

### Next objectives

* Integrate the docker develop by now into Kubernetes
* Deciding when to stop the docker/pod (when the user closes the application or when he closes the connection or both)
* Deciding which application we want to support
* Deciding stateless/statefull and where user config should be stored (if locally to the user or not)

#### Links of reference

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
