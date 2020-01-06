## Weekly report n°4 - Kubernetes on Desktop: offloading applications to a nearby worker node

Days of interest: 18/11/19 - 22/11/19


### Objective achieved

This week I not only tested and improved the first demo presented, but I've also implemented a demo of the application LibreOffice, as suggested.
Unfortunately, exporting the project on Kubernetes is not as easy as I thought, many problems came up and, while some of them are already addressed, others are in progress.

I wrote the yaml configuration file for both the deployment of the demo and the service (NodePort/LoadBalancer), but the latter still doesn't work at all.

### Next objectives

* Completing the integration in Kubernetes
* Addressing the volume problem (should mount a user computer local directory with the application specific configs or create a volume inside Kubernetes)
* Deciding which application we want to support
