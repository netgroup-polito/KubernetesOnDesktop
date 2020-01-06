## kubernetes

This directory contains all the yaml file used to deploy the various applications. In particular:

* `volume.yaml`: the config to mount a Persistent Volume Claim corresponding to the user directory 
* `deployment.yaml`: the generic deployment for each supported application (just modify `XXXXXXXXXX` with the desired application name)