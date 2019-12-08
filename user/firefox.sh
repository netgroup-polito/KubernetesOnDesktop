#!/bin/bash

#Timeout to wait for the pod creation (expressed in seconds)
timeout=20

#Start the kubernetes node
kubectl apply -f ../kubernetes/cloudfox-deployment.yaml

#Waiting for the pod to start
echo "Waiting for pod to start, max ${timeout}s"
kubectl wait --for=condition=Ready pod -l "app=cloudfox" --timeout=${timeout}s

if [ $? -eq 0 ]
then
	#Retrieving the ip/port of the node
	targetNodeIp=`kubectl get pod -l app=cloudfox -o "jsonpath={..status.hostIP}"`
	targetNodePort=`kubectl get svc cloudfox-service -o "jsonpath={.spec.ports[?(@.name=='vnc-port-tcp')].nodePort}"`
	
	echo "Connecting to TargetNodeIp: $targetNodeIp, TargetNodePort: $targetNodePort"
	
	#Setting up the ssh tunnel
	ssh -f -N -L 5900:localhost:5900 -p $targetNodePort root@$targetNodeIp
	
	#Start the vnc connections to the docker
	vncviewer localhost
else
  echo "Cannot create pod, running firefox locally"
  firefox --no-sandbox &
fi

#Clear deployment
kubectl delete -f ../kubernetes/cloudfox-deployment.yaml