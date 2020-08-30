## kubernetes

This directory contains all the kubernetes yaml file used to:
1. deploy the various applications. In particular:
    * `volume.yaml`: contains the configuration to mount a different Persistent Volume Claim for each application;
    * `deployment.yaml`: contains the generic deployment for each supported application (just modify `RAR_XXX_<...>` with the required values depending on the application name, the PID, the namespace and the secret containing the SSH public key);

2. deploy and run the vncviewer pod. In particular, `vncviewer.yaml` is a template that must be modified by the cloudify application, by replacing all the `RAR_XXX_<...>` parameters whith the right values, to make it possible to interact with both the host and the k8s pod running the specific application (e.g. Firefox).
