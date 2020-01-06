## Weekly report n°6 - Kubernetes on Desktop: offloading applications to a nearby worker node
​
Days of interest: 2/12/19 - 6/12/19
​
​
### Objective achieved
​
This week I dedicated myself to the encryption part of the communication with kubernetes. More in detail, I created a more secure CloudFox docker which, thanks to an ssh encrypted tunnel, can be connected to any client by means of authN. I started testing also the rook-ceph volume as Alex told me, to create an `home` environment for the user.
​
### Next objectives
​
* Improving the integration in Kubernetes
* Move authN from user/pass to token/certificate