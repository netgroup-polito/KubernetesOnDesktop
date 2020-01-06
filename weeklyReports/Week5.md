## Weekly report n°5 - Kubernetes on Desktop: offloading applications to a nearby worker node

Days of interest: 25/11/19 - 29/11/19


### Objective achieved

This week, as I already told, I got some troubles and I was not able to implement everything I wanted. Nevertheless, I started to integrate everything with Kubernetes, which turned out to be a little tricky, especially for investigating the new resource allocated to the client. Excluding these complications, which will be discussed in the following days with Alex, it seems to work smoothly (I tested it from my home connection which is really bad).

I have also thought of a possible solution concerning volumes: wouldn't be great if we mounted the user home (entirely or a part of, like the `Document` or `Download` folder) in the deployment? This way not only we would address the problem, but also we won't have to design internal and shared volumes in kubernetes.

### Next objectives

* Improving the integration in Kubernetes
* Addressing the volume problem (should mount a user computer local directory with the application specific configs or create a volume inside Kubernetes)
* Deciding which application we want to support
