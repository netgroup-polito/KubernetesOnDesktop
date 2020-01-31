## Solutions to accomplish Remote Desktop + Sound

In this section I analyze all the different possible solutions to achieve our goal. Despite of the wide choice of softwares, many of them don't fit our problem the best, since they are born to cover similar problem but in different scenarios.

As a reference, I've used the [following page](https://en.wikipedia.org/wiki/Comparison_of_remote_desktop_software) which lists all the available products. The analysis is performed only on free software for commercial use.

### RealVNC

RealVnc is not only the most used Remote desktop software, but it is also easy to learn, versatile and well maintained. Unfortunately, the free version doesn't allow you to transfer audio between the two endpoints of the connection. This is the main reason I decided to discard that option and move forward, looking for a complete and open-source one.

<https://www.realvnc.com/en/connect/audio/>

### SSH X forwarding

As a matter of fact, forwarding graphical application via ssh is a really handsome choice. However, this "protocol" is not thought to be used outside a LAN at all. In fact, whoever uses this solution needs to know that it is not a simple screen forwarding, but the packets sent between the host (the device running the application in its session) and the client (the device which renders the entire X session concerning that application) contain **ALL** the events that happen in the host OS. This means that the client has to draw the application window depending on that events, which are a lot.

Tested in a LAN this solution seemed to be the best one, because thanks to the complete session forwarding the client is able to reproduce, using its own physical devices, both video and audio.
But when I moved this implementation across the Internet to connect my laptop with a remote server hosting the X session in Turin, it turned out to be a complete failure, leading to huge delays and unusable window. The connection used to perform the tests is a 20 M bit.

### XPRA

XPRA is a GNU Screen X which allows users to run remote programs on your local screen and play remote audio locally. In addition, it has a lot of tuning parameters depending on connection, image quality, image encoding, etc. which allows you to decide how to improve the streaming. XPRA is a ready-to-use software, you actually don't need to configure anything else, except in our case we have to figure out how to make it works in an unusual Linux installation (headless Docker). By the way, before getting ready to figure it out, I tested it on my LAN and, unfortunately, it didn't behave as I expected. In fact, SSH X forwarding seemed not only more reactive, but the latency was almost zero, while using XPRA and playing a remote video on Youtube led to 5 seconds of delay between audio and video in spite all the tuning suggestions. Since it didn't work at the best in a LAN, I think that via Internet this solution can only worsen.

<https://www.xpra.org/trac/wiki/Encodings>
<https://hub.docker.com/r/enricomariam42/x11-xpra/dockerfile>
<https://xpra.org/trac/wiki/Authentication>
<https://github.com/bencawkwell/dockerfile-xpra/blob/master/Dockerfile>
<https://gstreamer.freedesktop.org/documentation/installing/on-linux.html?gi-language=c>
<https://xpra.org/trac/wiki/Dependencies>

### SPICE

One of the many protocol supported by Remmina, a famous client for Remote Desktop, is Spice. Surprisingly, it supports also the audio feature, thanks to the connected client can also reproduce audio from the server. Digging deeper, I discovered that SPICE is basically a tunneled X11 connection, which means that it carries all the X session events as the SSH X forwarding method does. As a result, I didn't test it, since it would led to the same or even worse result.

<https://www.reddit.com/r/linux/comments/mlmbj/not_many_people_know_about_spice_and_what_is/>

### XRDP + Remmina

RDP is a windows protocol which supports both audio and video redirection, which is good. However, to make it work in Linux we have to use xRDP which is an implementation of RDP in X environments. This may seem good, but to make it work we have to install and compile Pulseaudio from source (since xRDP supports only a specific version) and manually download and compile kernel modules to enable audio forwarding via this protocol. 

The advantage of this architecture is that once everything is correctly setup, also Windows clients can connect to our Docker and achieve the same result of Linux ones, since in Windows the RDP protocol is natively supported and perfectly works.

Fortunately. surfing the net trying to understand better this scenario I got into [this](https://hub.docker.com/r/danielguerra/ubuntu-xrdp/) link. It's exactly what we are trying to build, a completely working docker image of Ubuntu with the XRDP environment already set to forward also the audio. The only cons is that this docker contains a full Ubuntu installation including the desktop environment which, in our scenario, is useless. A smart choice would be to take this repository and adapt it to our needs, in case we would choose RDP as protocol.
Testing this installation on my LAN led to interesting results: the video/image streaming is very good as in every VNC connections; the audio works, but it is not understandable since it stops every second; if you pause the video, the audio streaming will continue smoothly until it is up to date. This could be due my 20 M bit connection, but we have to take it into account if we want to deploy a Kubernetes-based Linux system which works also out of our LAN.

Remmina in that scenario would be a perfect and efficient client to connect to the server hosting the application. Moreover, due to its high reconfigurability user can easily modify parameters such as audio, display size, etc. to its flavor. Another client solution could be freeRDP.

<https://c-nergy.be/blog/?p=12469>
<https://linuxize.com/post/how-to-install-xrdp-on-ubuntu-18-04/>
<https://wiki.archlinux.org/index.php/Xrdp>
<https://github.com/neutrinolabs/pulseaudio-module-xrdp/wiki/README>
<https://www.reddit.com/r/sysadmin/comments/8j68pv/linux_based_rdp_server/>
https://hub.docker.com/r/danielguerra/firefox-rdp/dockerfile

### Tiger/Tight/X11-VNC (+ PulseAudio server)

Both these three vnc client/server technologies are famous and widely used in Linux. Although, they are known to not support audio forwarding. In fact, the VNC protocol, which is completely different from the X forwarding one, allows client to connect to a server (or a specific application running on that server) smoothly, with an high responsive and re-sizable window, but it does not include audio transmission like in RealVNC pro version. Basically it fits every our needs except the audio.

Interestingly, PulseAudio works on an audio server which typically is set to a local port in Linux installation. As stated in every PulseAudio guide/documentation, users can set a remote server to delegate the audio reproduction to, accomplishing our objective. Even if it hasn't been tested yet, since the audio transmission can be binded both in clear (on a local TCP port) or encrypted (using the ssh tunneling method), I can guess that this choice is probably the best one and allows us to configure everything as we want. The Pulseaudio server transmission will be installed and used only on those images which require the audio reproduction like Firefox, Spotify, etc. (in the LibreOffice image we won't handle it since useless). There is a tricky part though: the docker image has to set the IP address of our computer as its Pulseaudio server, but what if we are behind a NAT as we probably will be? The solution would be opening another port on the node running our application which will be then forwarded to our computer.

However, after many days of trials and installation, I am still not able to make it work, since we don't have a complete OS installation in our Docker images (to avoid useless overhead), thus I'm digging to find out one-by-one the needed packages/configuration. 

<https://joshdata.wordpress.com/2009/02/11/pulseaudio-sound-forwarding-across-a-network/>
<https://unix.stackexchange.com/questions/105964/launch-a-fake-minimal-x-session-for-pulseaudio-dbus>
<https://unix.stackexchange.com/questions/138350/how-can-i-forward-sound-over-vnc>
<https://joshdata.wordpress.com/2009/02/11/pulseaudio-sound-forwarding-across-a-network/>
<https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio>

#### Commands to make it work in a complete Ubuntu installation
```
Device with the speaker -> `pactl load-module module-native-protocol-tcp port=34567 auth-ip-acl=172.17.0.2`

Docker image -> `... --env PULSE_SERVER=tcp:172.17.0.1:34567`

Packages installed on a normal ubuntu complete installation:

* gstreamer0.10-pulseaudio
* gstreamer1.0-pulseaudio
* libcanberra-pulse
* libcanberra-pulse-dbg
* libpulse-dev
* libpulse-jni
* libpulse-mainloop-glib0
* libpulse-ocaml
* libpulse-ocaml-dev
* libpulse0
* libpulsedsp
* libsox-fmt-pulse
* libquidsoap-plugin-pulseaudio
* osspd-pulseaudio
* paman
* paprefs
* pasystray
* pavucontrol
* pavumeter
* projectm-pulseaudio
* pulseaudio
* pulseaudio-esound-compat
* pulseaudio-module-bluetooth
* pulseaudio-module-droid
* pulseaudio-module-gconf
* pulseaudio-module-jack
* pulseaudio-module-lirc
* pulseaudio-odule-raop
* pulseaudio-module-trust-store
* pulseaudio-module-x11
* pulseaudio-module-zeroconf
* pulseaudio-utils
* snd-gtk-pulse
* xfce4-pulseaudio-plugin
* xmms2-plugin-pulse
```

### Example of a working noVNC container with WEB-based audio streaming

<https://blog.nediiii.com/dockerize-gui-app/>
