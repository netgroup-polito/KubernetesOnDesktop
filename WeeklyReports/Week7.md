## Weekly report n°7 - Kubernetes on Desktop: offloading applications to a nearby worker node
​
Days of interest: 9/12/19 - 13/12/19
​
### Objective achieved
​
Despite all the inconveniences, this week was the most productive one. In fact, I accomplished the following tasks:

* Implemented an optimal Firefox Docker image
* Implemented an optimal Libreoffice Docker image
* Created deployment for the user home directory
* Completed Firefox deployment
* Completed Firefox deployment
* Integrated encryption in connections
* Written documentation both for the entire project and for the sub-directories
* Finalized the user script to launch application with the following features:
	* Checking the network performance to decide whether to run the application locally or in Cloud
	* Checking user input argument to decide which connection to be used (clear or encrypted)
	* Checking remote port forwarding on node hosting the pod
	* Correctly catching Ctrl+C and cleaning resources

### Next objectives
​
* Improve last configuration in docker images
* Finalize documentation
* Modify system call exec