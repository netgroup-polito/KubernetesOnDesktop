## kubernetes

This directory contains all the yaml file used:

1 - to deploy the various applications. In particular:
    * `volume.yaml`: the config to mount a different Persistent Volume Claim for each application
    * `deployment.yaml`: the generic deployment for each supported application (just modify `XXXXXXXXXX` with the desired application name)


2 - to deploy and run the vncviewer pod. In particular, `vncviewer.yaml` is a template that must be modified by the cloudify application,
    by replacing all the "RAR_" parameters whith the right values, to make it possible to interact with both the host and the k8s pod
    running the specific application (e.g. Firefox).
