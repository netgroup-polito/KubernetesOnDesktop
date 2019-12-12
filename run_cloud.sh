#!/bin/bash

function start_deploy {
	enc=$1
	targetDeploy="kubernetes/clear/${application_name}-deployment.yaml"
  
  if [ $enc -eq 1 ]
  then
  	targetDeploy="kubernetes/enc/${application_name}-deployment.yaml"
  fi

  #Start the kubernetes node
	kubectl apply -f $targetDeploy

	if [ $? -eq 0 ]
	then
	
	#Waiting for the pod to start
	echo "Waiting for pod to start, max ${timeout}s"
	kubectl wait --for=condition=Ready pod -l "app=${application_name}" --timeout=${timeout}s
	
		if [ $? -eq 0 ]
		then
			#Retrieving the ip/port of the node
			targetNodeIp=`kubectl get pod -l app=${application_name} -o "jsonpath={..status.hostIP}"`
			targetNodePort=`kubectl get svc ${application_name}-service -o "jsonpath={.spec.ports[?(@.name=='vnc-port-tcp')].nodePort}"`
			
			echo "Connecting to TargetNodeIp: $targetNodeIp, TargetNodePort: $targetNodePort"
			
			if [ $enc -eq 1 ]
			then
				#Setting up the ssh tunnel
				ssh -f -N -L 5900:localhost:5900 -p $targetNodePort root@$targetNodeIp
				#Start the vnc connections to the docker
				vncviewer localhost
			else
				#Start the vnc connections to the docker
				vncviewer $targetNodeIp::$targetNodePort -passwd <(echo default | vncpasswd -f)
			fi
		else
		  echo "Cannot create pod, running ${application_name} locally"
		  ${application_name} &
		fi
	else
		echo "Cannot apply deployment, running ${application_name} locally"
		${application_name} &
	fi

	#Clear deployment
	kubectl delete -f $targetDeploy
	exit
}

if [ "$#" -ne 1 ]; then
    echo "Usage: ./run_cloud.sh <application_name>"
    exit
fi

#Timeout to wait for the pod creation (expressed in seconds)
timeout=20
application_name=$1

echo "Do you wish to encrypt connection?"

select yn in "Yes" "No"; do
	case $yn in
    Yes ) start_deploy 1 $1; break;;
    No ) start_deploy 0 $1;;
	esac
done
