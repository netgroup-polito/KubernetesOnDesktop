#!/bin/bash

#Timeout to wait for the pod creation (expressed in seconds)
timeout=60
#The Persistent Volume Claim deployment
pvcDeploy="kubernetes/volume.yaml"
#Variable to select connection type, 0=clear, 1=encrypted
enc=0
#Variables to decide the screen size
width=1280
height=760
supported_apps=("firefox" "libreoffice")

function adjust_screen {
	wline=`grep -n 'DISPLAY_WIDTH' ${targetDeploy} | cut -d : -f -1`
	hline=`grep -n 'DISPLAY_HEIGHT' ${targetDeploy} | cut -d : -f -1`
	((wline=wline+1))
	((hline=hline+1))
	
	sed -i "${wline}s/[0-9]\+/${width}/" ${targetDeploy}
	sed -i "${hline}s/[0-9]\+/${height}/" ${targetDeploy}
}

function adjust_encription {
	#If the user requires encryption, uncomment deployment parameter
	#otherwise comment it if it is not already commented
  if [ ${enc} -eq 1 ]; then
  	sed -e '/SECURE_CONNECTION/,+1 s/^#*//' -i ${targetDeploy}
  else
  	sed -e '/SECURE_CONNECTION/,+1 s/^#*/#/' -i ${targetDeploy}
  fi
}

#Main function to start the deployment of the desider application
function start_deploy {
	
	adjust_screen

	adjust_encription
	
  #Using a default cluster IP before knowing the real one.
  #We can assume that the network speed isn't different at all.
  echo -n "Measuring network speed..."
  netspeed=`iperf -c 130.192.225.70 -u -i 1 -t 1 2>/dev/null| grep -Po '[0-9.]*(?= Mbits/sec)'`
	echo "OK ${netspeed} Mbit/s"

	#Checking network speed availability
	if [[ $(echo "${netspeed}>0.5" | bc) -eq 1 ]]; then
		
		echo -n "Applying deploy..."
		#Start both deploy and volume
  	kubectl apply -f $pvcDeploy &>/dev/null && kubectl apply -f $targetDeploy &>/dev/null
	
		if [ $? -ge 0 ]; then
			echo "OK"
			#Register Ctr+C interrupt
			trap clear_and_exit INT

			#Waiting for the pod to start
			echo -n "Waiting for pod to start, max ${timeout}seconds..."
			kubectl wait --for=condition=Ready pod -l "app=${application_name}" --timeout=${timeout}s &>/dev/null

			if [ $? -eq 0 ]; then
				echo "OK"
				
				echo -n "Retrieving node IP and PORT..."
				#Retrieving the ip/port of the node
				targetNodeIp=`kubectl get pod -l app=${application_name} -o "jsonpath={..status.hostIP}"`
				targetNodePort=`kubectl get svc ${application_name}-service -o "jsonpath={.spec.ports[?(@.name=='vnc-port-tcp')].nodePort}"`
				echo "OK ${targetNodeIp}:${targetNodePort}"
				
				echo -n "Waiting for the NodePort to be opened..."
				while ! nc -z ${targetNodeIp} ${targetNodePort}; do   
					echo -n "."
  				sleep 1 
				done
				echo "OK"
				
				#Check encryption, if yes -> start vnc encrypted connection
				#otherwise -> start normal vnc connection
				if [ $enc -eq 1 ]; then
					echo "Starting encrypted connection..."
					ssvnc $targetNodeIp:$targetNodePort -nvb -killstunnel 2>/dev/null
				else
					echo "Starting clear connection..."
					vncviewer $targetNodeIp::$targetNodePort -passwd <(echo "default" | vncpasswd -f) 2>/dev/null
				fi
				echo "OK"
				clear_and_exit 0
			else
				echo "ERROR"
		 	 	echo "Cannot create pod, running ${application_name} locally"
			fi
		else
			echo "ERROR"
			echo "Cannot apply deployment, running ${application_name} locally"
		fi
	else
		echo "Your internet connection is too slow, running ${application_name} locally"
	fi
	${application_name} &>/dev/null &
	clear_and_exit 0
}

#Delete only the deployment NOT the pvc
function clear_and_exit {
	echo
	echo -n "Deleting deploy..."
	kubectl delete -f $targetDeploy &>/dev/null
	echo "OK"
	exit $1
}

#Print usage function
function print_usage_and_exit {
	echo "Run application in Cloud using Kubernetes as orchestrator."
	echo "Usage: ./run_cloud.sh [-h] [-i] [-e] [-d screen_resolution] [-t timeout] <application_name>"
	echo "|-> -h: start the helper menu"
	echo "|-> -i: start the script in interactive mode"
	echo "|-> -e: specify that the connection must be encrypted"
	echo "|-> -d: specify the resolution to be used (ex. 1920x1080)"
	echo "|-> -t: connection/wait timeout in seconds (ex. 10)"
	echo "|"
	echo "|->Example: ./run_cloud.sh firefox"
	echo "|->Example: ./run_cloud.sh -d 1920x1080 -t 10 -e firefox"
	exit $1
}

function retrieve_screen_dim {
	echo -n "Reading screen dimensions...OK "
	read -r width height <<<$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/' | sed 's/x/ /g')
	echo "${width}x${height}"
}

function start_interactive {
	echo "Do you wish to encrypt connection?"
	select yn in "Yes" "No"; do
		case $yn in
   	 Yes ) enc=1; break;;
   	 No )  enc=0; break;;
		esac
	done
}

function main() {
	#Retrieving the name of the application passed as last argument
	for application_name in $@; do :; done
	#The target deployment file
	targetDeploy="kubernetes/${application_name}-deployment.yaml"
	
	if [ $# -lt 1 ] || ! ( IFS=$'\n'; echo "${supported_apps[*]}" ) | grep -qFx "$application_name" &>/dev/null; then
		print_usage_and_exit 1
	fi

	retrieve_screen_dim &>/dev/null

	while getopts "ihd:et:" opt; do
  	case $opt in
	    d)
				echo "$OPTARG" | grep -P -q '\d+x\d+'
	      if [ $? -eq 0 ]; then
	      	read -r width height <<<$(echo $OPTARG | sed 's/x/ /g')
	      	echo "Parameters SCREEN_DIMENSION...OK ${width}x${height}"
	      else
	      	echo "Parameters SCREEN_DIMENSION...INVALID, using default one (${width}x${height})"
	      fi
	      ;;
	    e)
	      enc=1
	      echo "Parameter ENCRYPTION...OK"
	      ;;
	    t)
				if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
					timeout=$OPTARG
					echo "Parameter TIMEOUT...OK ${timeout}"
				else
					echo "Parameter TIMEOUT...INVALID, using default one (${timeout} seconds)"
				fi
	      ;;
	    h)
				print_usage_and_exit 0
				;;
			i)
				echo "Starting interactive..."
				start_interactive
				;;
	    \?)
				print_usage_and_exit 1
	      ;;
	  esac
	done

	start_deploy
	exit 0
}

main $@