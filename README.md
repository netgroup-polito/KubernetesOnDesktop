# Kubernetes On Desktop

Developed by: 
* **Simone Magnani** (release/v1.0) 
* **Antonio Riccardo Roccaro** (release/v2.0)

Tutor: **Fulvio Risso** - **Alex Palesandro**

Version: v2.0

Presentation slides: 
* [KubernetesOnDesktop release/v1.0 - Magnani](https://docs.google.com/presentation/d/15Dj8vwPaAyB_QmC_4886_E1K4pc7DzzlEPeiWJJMcCI/edit#slide=id.g742e3e7cd_1_16)
* [KubernetesOnDesktop release/v2.0 - Roccaro](https://docs.google.com/presentation/d/16z3NjHMjUr7YS_KgGWZ5komRSfAWSNqNonW72dKzagI/edit?usp=sharing)

## Introduction

KubernetesOnDesktop is a university project with the aim of developing a cloud infrastructure to run user application in a remote cluster.

Thanks to the Netgroup Polito cluster, we have developed a very high performing infrastructure to let correctly configured users deploy applications and connect to them via many protocols.

To make modifications persistent, we decided to create a PersistentVolumeClaim for each different kind of application, thanks to all the users preferences are restored at every execution to improve the experience. 

The actual program supported are Firefox and Libreoffice. The execution unit will be destroyed together with all the deployments once the user has finished to use it.

Interestingly, depending on the connection quality and on the pod availability, the required application will be executed in Cloud or in the local user computer. This is a user-friendly feature not to alter the normal execution behavior in certain particular cases.

Everything is tunable user-side like connection quality, program executed, compression, encryption etc.

## Technologies used

* TigerVNC
* NoVNC
* SSH server
* Openbox (light window manager)
* Some utility tools (wget, net-tools, locales, xdotool, python-numpy used for websockify/novnc, xorg)
* Firefox/Libreoffice (once per docker image)

These not only allows our infrastructure to be reachable both via a VNC client and browser, but they also ensure that everything fits user needs and tastes.

## Dependencies

* Kubectl
* VNC viewer
* vncpasswd (present in any vnc server package)
* Netcat

VNC viewer is required only in native mode execution. In the other cases (docker or k8s pod) it is already integrated inside the docker image.

While Kubectl is mandatory, Netcat and VNC viewer can be replaced by other application modifying the script. However, make sure that the ones you want to use are compatible with all the parameters (quality, compression), otherwise you may not achieve the same result.

**Note**

Due to the usage of `vncpasswd` command to automatically encrypt the password from the command line, also the vncserver dependency should be installed
while using native run mode. There are no current `vncpasswd` standalone installation.

## Supported Applications

This is the first version of the project, so we preferred to focus on the quality of our services instead than the quantity.

The supported ones are:

* Firefox
* Libreoffice

## How it works

For the sake of simplicity, in this draw it has been omitted the entire network infrastructure (routers, other servers on cluster, etc.) of the cluster, leaving only the element in question.  


![Infrastructure](doc_images/Infrastructure.png)

### Deployment Phases

As first, network connectivity and speed is checked in order to decide whether to run the application locally or in the cluster. To accomplish that, we have used a simple `kubectl get pods` command, because it not only allows us to understand if network is up, but it also tells us your network/cluster condition. We could have used a `kubectl get version` command, but it is always very reactive and sometimes cached, while getting all pods (or every other resource) requires a bit of computation, which is cool to be considered.

The second step is to modify the deployment file according to the user preferences. In fact, the template file contains all the possible combination of port/services used, and the `cloudify` script modifies them at every execution to deploy the desired system. Once finished, the deploy is applied to the cluster and, if it succeeds, the script looks for all the useful information like the IP to contact, the PORT opened for the services and the assigned pod name. Furthermore, in the mean time it is automatically generated a new SSH key pair with no passphrase to be used as authN for the new connection. The SSH keys are extremely important, since they are used to map the remote pod PulseAudio local port to the user PulseAudio TCP server, launched later.

Once gathered pod's information, the program waits for the pod to change it's state to RUNNING, meaning that it's ready to be contacted. Of course every phase has its own controls to be sure that the following step executes only if all the previous succeeded. In this phase the public RSA key is copied to the specific pod and it is started the local PulseAudio TCP server. The user is now ready to connect.

The connection can be done in three different execution modes:
1 - Native mode (by running cloudify with -r 0 option), that use the standalone vncviewer installation inside the local machine;
2 - Docker mode (by running cloudify with -r 1 option), that use a docker image containing the vncviewer installation and all the other required packages;
3 - K8s pod mode (by running cloudify with -r 2 option), that use the same docker image but its scheduling is done by k8s on the local machine that must a node of the k8s cluster.

In every cases, the connection phase starts with a mandatory remote port forwarding for the audio and an optional local port forwarding for the encrypted VNC/noVNC connection, depending whether the encryption has been previously enable or not. If these command succeed, the connection starts using the right client (vncviewer or a browser).

A huge difference between the two client is that if a vncviewer is used, the user has still the possibility to change at run time some parameter to tune the connection quality as he wants, while if it using noVNC this is not allowed.

Finally, once the client terminates, the script handles the final phase, where the deploy is remotely deleted, the ssh connections are closed and the PulseAudio TCP server is shut down.

### SSH keys and One time Token

As previously anticipated, each run generates a new SSH key pair in the directory `/tmp/Cloudify/` where also the used deployment has been copied. These information are one-shot, meaning that the next run will generate new ones starting from scratch. 

Even though user chooses not to encrypt the connection, the vnc session, that in this case could be sniffed with a MITM attack, is still password-protected. The password is a One Time Token generated before applying the deploy remotely and will be used to connect to the pod both with the two protocols. In case of noVNC, a pop-up with your secret token will appear on your screen, allowing you to copy and paste it directly in your browser.


## Usage

Once all the dependencies are installed, since it is a cloud based application you don't have to install anything else.

The user must use the `cloudify` script to launch application, or use the various desktop launchers created. It is strongly suggested that he has a local installation of that application, since the script will automatically launch it if there are some connection or cluster availability errors.

To use it, type in a terminal:

```bash
user@hostname:~/WorkingDirectory$ ./cloudify firefox
```

Actually there are a lot of optional parameter as reported in the script usage:

```bash
Run application in Cloud using Kubernetes as orchestrator.
Usage: ./cloudify [-h] [-e] [-t timeout] [-p protocol] [-q quality] [-c compression] [-r runmode] app_name
|-> -h: start the helper menu
|-> -e: specify that the connection must be encrypted (0/1, default 0 disabled)
|-> -t: connection/wait timeout in seconds (positive number, default 60)
|-> -p: connection protocol to be used (vnc/novnc, default vnc)
|-> -q: specify the quality of the connection (0-9, default 5)
|-> -c: specify the compression of the connection (0-6, default 2)
|-> -r: vncviewer run mode:
|       0-> native app
|       1-> docker container
|       2-> k8s pod
|       default-> 0 (native app).
|       Warning: this option can't be used if '-p novnc' is set
|
|->Example: ./cloudify firefox
|->Example: ./cloudify -q 7 -t 10 -e firefox
|->Example: ./cloudify -q 7 -t 10 -e -r 1 firefox
```

If everything was correct, a vncviewer window rendering the application will appear. Interestingly, you now not only can play the remote audio, but also controlling it. 

Firefox (VNC)

![Firefox using VNC](doc_images/Firefox.png)

Firefox (noVNC)

![Firefox using noVNC](doc_images/Firefox2.png)


## Acknowledgments

Professor Risso

* <https://github.com/frisso>

PhD Alex Palesandro

* <https://github.com/palexster>
