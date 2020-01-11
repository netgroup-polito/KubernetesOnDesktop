#!/bin/bash

#Timeout to wait for the pod creation (expressed in seconds)
timeout=60
#The Persistent Volume Claim deployment
pvcDeploy="kubernetes/volume.yaml"
#The target deployment file
targetDeploy="kubernetes/deployment.yaml"
#Variable to select connection type, 0=clear, 1=encrypted
enc=0
#Variables to decide the screen size
width=1280
height=760
#List of supported apps
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
	line=`grep -n 'SECURE_CONNECTION' ${targetDeploy} | cut -d : -f -1`
	((line=line+1))

	sed -i "${line}s/[0-1]/${enc}/" ${targetDeploy}	
}

function adjust_deploy {
	if [ $1 -eq 1 ]; then
		sed -i "s/${application_name}/XXXXXXXXXX/" ${targetDeploy}
	else
		sed -i "s/XXXXXXXXXX/${application_name}/" ${targetDeploy}
	fi
}

function adjust_token {
	line=`grep -n 'VNC_PASSWORD' ${targetDeploy} | cut -d : -f -1`
	((line=line+1))
	
	sed -i "${line}s/\".*\"/\"$1\"/" ${targetDeploy}
}

#Main function to start the deployment of the desider application
function start_deploy {
	
	adjust_screen

	adjust_encription

	adjust_deploy 0
	
  #Checking connectivity
  echo -n "Checking connectivity..."
  nettime=$( TIMEFORMAT="%3U + %3S"; { time timeout 2 kubectl describe pods; } 2>&1)

  if [ $? -eq 0 ]; then
  	#Parsing previous output to get sum of seconds
  	nettime=$(echo ${nettime} | sed 's/,/./g' |  awk '{printf "%f", $1 + $2}')
		
		#Checking network speed availability
		if [[ $(echo "${nettime}<0.5" | bc) -eq 1 ]]; then
			
			echo "OK cluster answered in ${nettime} seconds"
			
			echo -n "Generating token..."
			token=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
			echo "OK"

			adjust_token ${token}

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
					echo "OK pod running"
					
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
					echo "OK port opened"
					
					#Check encryption, if yes -> start vnc encrypted connection
					#otherwise -> start normal vnc connection
					if [ $enc -eq 1 ]; then
						echo "Starting encrypted connection..."
						ssvnc -cmd $targetNodeIp:$targetNodePort -passwd <(echo ${token} | vncpasswd -f) > /dev/null 2>&1
					else
						echo -n "Starting clear connection..."
						vncviewer $targetNodeIp::$targetNodePort -passwd <(echo ${token} | vncpasswd -f) 2>/dev/null
					fi
					echo "OK"
					clear_and_exit 0
				else
					echo "ERROR cannot create pod, running ${application_name} locally"
				fi
			else
				echo "ERROR cannot apply deployment, running ${application_name} locally"
			fi
		else
			echo "ERROR cluster answered in ${nettime} seconds (too slow), running ${application_name} locally"
		fi
	else
		echo "ERROR no internet, running ${application_name} locally"
  fi
	${application_name} &>/dev/null &
}

#Delete only the deployment NOT the pvc
function clear_and_exit {
	echo
	echo -n "Deleting deploy..."
	kubectl delete -f $targetDeploy &>/dev/null
	echo "OK"
	adjust_deploy 1
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
	clear_and_exit 0
}

main $@