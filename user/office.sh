#!/bin/bash

#Start the kubernetes node
kubectl apply -f ../kubernetes/cloudoffice-deployment.yaml

echo "Waiting for the container to start"
sleep 5

targetNodeIp=`kubectl get pods -o yaml | grep -m 1 "hostIP" | awk '{print $2}'`
targetNodePort=`kubectl get services | grep "cloudoffice-service" | awk '{print $5}' | grep -E -o '[0-9]{5}'`

echo "Connecting to TargetNodeIp:$targetNodeIp, TargetNodePort:$targetNodePort"

#Start the vnc connections to the docker
vncviewer $targetNodeIp::$targetNodePort -passwd <(echo default | vncpasswd -f)

kubectl delete -f ../kubernetes/cloudoffice-deployment.yaml