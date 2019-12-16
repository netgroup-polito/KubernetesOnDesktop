## Old-enc

This directory refers to a previous version of the Kubernetes deployment in case the user wants to encrypt the communication.
Since my old docker images were ssh-based, these command allowed you to create a ssh tunnel to localhost and directly connect to it.

```bash
#Setting up the ssh tunnel
ssh -f -N -L 5900:localhost:5900 -p $targetNodePort root@$targetNodeIp
#Start the vnc connections to the docker
vncviewer localhost
```