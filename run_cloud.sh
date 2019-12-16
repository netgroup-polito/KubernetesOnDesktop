#!/bin/bash

#Timeout to wait for the pod creation (expressed in seconds)
timeout=30
#The name of the application passed as first argument
application_name=$1
#The target deployment file
targetDeploy="kubernetes/${application_name}-deployment.yaml"
#The Persistent Volume Claim deployment
pvcDeploy="kubernetes/volume.yaml"

#Main function to start the deployment of the desider application
function start_deploy {
	enc=$1
	
	#If the user requires encryption, uncomment deployment parameter
	#otherwise comment it if it is not already commented
  if [ $enc -eq 1 ]; then
  	sed -e '/SECURE_CONNECTION/,+1 s/^#*//' -i ${targetDeploy}
  else
  	sed -e '/SECURE_CONNECTION/,+1 s/^#*/#/' -i ${targetDeploy}
  fi

  #Using a default cluster IP before knowing the real one.
  #We can assume that the network speed isn't different at all.
  netspeed=`iperf -c 130.192.225.70 -u -i 1 -t 1 | grep -Po '[0-9.]*(?= Mbits/sec)'`
	
	#Checking network speed availability
	if [[ $(echo "${netspeed}>0.5" | bc) -eq 1 ]]; then
		
		#Start both deploy and volume
  	kubectl apply -f $pvcDeploy && kubectl apply -f $targetDeploy
	
		if [ $? -ge 0 ]; then
			#Register Ctr+C interrupt
			trap ctrl_c INT

			#Waiting for the pod to start
			echo "Waiting for pod to start, max ${timeout}s"
			kubectl wait --for=condition=Ready pod -l "app=${application_name}" --timeout=${timeout}s
	
			if [ $? -eq 0 ]; then
				#Retrieving the ip/port of the node
				targetNodeIp=`kubectl get pod -l app=${application_name} -o "jsonpath={..status.hostIP}"`
				targetNodePort=`kubectl get svc ${application_name}-service -o "jsonpath={.spec.ports[?(@.name=='vnc-port-tcp')].nodePort}"`

				echo -n "Waiting for the NodePort to be opened"
				while ! nc -z ${targetNodeIp} ${targetNodePort}; do   
					echo -n "."
  				sleep 1 
				done

				echo "Connecting to TargetNodeIp: $targetNodeIp, TargetNodePort: $targetNodePort"
			
				#Check encryption, if yes -> start vnc encrypted connection
				#otherwise -> start normal vnc connection
				if [ $enc -eq 1 ]; then
					ssvnc $targetNodeIp:$targetNodePort -nvb -killstunnel
				else
					vncviewer $targetNodeIp::$targetNodePort -passwd <(echo "default" | vncpasswd -f)
				fi
			else
		 	 echo "Cannot create pod, running ${application_name} locally"
		 	 ${application_name} &
			fi
			clear_and_exit
		else
			echo "Cannot apply deployment, running ${application_name} locally"
			${application_name} &
		fi
	else
		echo "Your internet connection is too slow, running ${application_name} locally"
		${application_name} &
	fi
}

#Delete only the deployment NOT the pvc
function clear_and_exit() {
	kubectl delete -f $targetDeploy
	exit
}

#Print usage function
function print_usage_and_exit() {
	echo "Run cloud application specifying the typology and an optional attempt to connect timeout parameter."
	echo "Usage: ./run_cloud.sh <application_name> [<timeout>]"
	echo "|->Example: ./run_cloud.sh firefox"
	echo "|->Example: ./run_cloud.sh firefox 2"
	exit
}

function main() {
	#Checking input application argument, maybe in the future it has to be
	#checked the application within a list of supported
	if [ "$#" -lt 1 ] || [ $1 == "-h" ] || [ $1 == "--help" ]; then
    print_usage_and_exit
	fi

	#Checking if inserted a timeout
	if [ "$#" -eq 2 ] && [[ $2 =~ ^-?[0-9]+$ ]]; then
		timeout=$2
	fi

	echo "Do you wish to encrypt connection?"

	select yn in "Yes" "No"; do
		case $yn in
   	 Yes ) start_deploy 1; break;;
   	 No ) start_deploy 0;;
		esac
	done
}

main $@