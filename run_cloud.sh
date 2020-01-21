#!/bin/bash

#Protocol to be used (default VNC)
protocol="vnc"
#Timeout to wait for the pod creation (expressed in seconds)
timeout=60
#Seconds for the server response to consider a good connection
connection_answer_time=1
#The Persistent Volume Claim deployment
pvcDeploy="kubernetes/volume.yaml"
#The target deployment file
targetDeploy="kubernetes/deployment.yaml"
#Variable to select connection type, 0=clear, 1=encrypted
enc=0
#Variables to decide the screen size
width=1280
height=760
#Variable which tracks if the deployment has successfully been launched
deployed=0
#List of supported apps
supported_apps=("firefox" "libreoffice")
supported_protocols=("vnc" "novnc" "xrdp")

#Set screen dimensions
function adjust_screen {
	wline=`grep -n 'DISPLAY_WIDTH' ${targetDeploy} | cut -d : -f -1`
	hline=`grep -n 'DISPLAY_HEIGHT' ${targetDeploy} | cut -d : -f -1`
	((wline=wline+1))
	((hline=hline+1))
	
	sed -i "${wline}s/[0-9]\+/${width}/" ${targetDeploy}
	sed -i "${hline}s/[0-9]\+/${height}/" ${targetDeploy}
}

#Set SECURE_CONNECTION to 1/0 depending on encryption
function adjust_encription {
	line=`grep -n 'SECURE_CONNECTION' ${targetDeploy} | cut -d : -f -1`
	((line=line+1))

	sed -i "${line}s/[0-1]/${enc}/" ${targetDeploy}	
}

#Set application name in deployment
function adjust_appname {
	sed -i "s/XXXXXXXXXX/${application_name}/" ${targetDeploy}
}

#Set the new generated token
function adjust_token {
	line=`grep -n 'VNC_PASSWORD' ${targetDeploy} | cut -d : -f -1`
	((line=line+1))
	
	sed -i "${line}s/\".*\"/\"$1\"/" ${targetDeploy}
}

#Comment/Uncomment services and ports depending on protocol used
function adjust_protocol {
	from_novnc_service=`grep -w -n 'novnc-svc-port' ${targetDeploy} | cut -d : -f -1`
	((till_novnc_service=from_novnc_service+3))
	from_vnc_service=`grep -w -n 'vnc-svc-port' ${targetDeploy} | cut -d : -f -1`
	((till_vnc_service=from_vnc_service+3))
	from_xrdp_service=`grep -w -n 'xrdp-svc-port' ${targetDeploy} | cut -d : -f -1`
	((till_xrdp_service=from_xrdp_service+3))
	from_novnc_container=`grep -w -n 'novnc-cont-port' ${targetDeploy} | cut -d : -f -1`
	((till_novnc_container=from_novnc_container+1))
	from_vnc_container=`grep -w -n 'vnc-cont-port' ${targetDeploy} | cut -d : -f -1`
	((till_vnc_container=from_vnc_container+1))
	from_xrdp_container=`grep -w -n 'xrdp-cont-port' ${targetDeploy} | cut -d : -f -1`
	((till_xrdp_container=from_xrdp_container+1))

	if [ "$protocol" = "vnc" ]; then
		sed -i "${from_xrdp_service},${till_xrdp_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_xrdp_container},${till_xrdp_container} {s/^/#/}" ${targetDeploy}
		sed -i "${from_novnc_service},${till_novnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_novnc_container},${till_novnc_container} {s/^/#/}" ${targetDeploy}
	elif [ "$protocol" = "novnc" ]; then
		sed -i "${from_xrdp_service},${till_xrdp_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_xrdp_container},${till_xrdp_container} {s/^/#/}" ${targetDeploy}
		sed -i "${from_vnc_service},${till_vnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_vnc_container},${till_vnc_container} {s/^/#/}" ${targetDeploy}
	else
		sed -i "${from_novnc_service},${till_novnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_novnc_container},${till_novnc_container} {s/^/#/}" ${targetDeploy}
		sed -i "${from_vnc_service},${till_vnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_vnc_container},${till_vnc_container} {s/^/#/}" ${targetDeploy}
	fi
}

function connect {
	if [ "$protocol" = "vnc" ]; then
		#Check encryption, if yes -> start vnc encrypted connection
		#otherwise -> start normal vnc connection
		if [ $enc -eq 1 ]; then
			echo "Starting encrypted VNC connection..."
			ssvnc -cmd $targetNodeIp:$targetNodePort -passwd <(echo ${token} | vncpasswd -f) > /dev/null 2>&1
		else
			echo -n "Starting clear VNC connection..."
			vncviewer $targetNodeIp::$targetNodePort -passwd <(echo ${token} | vncpasswd -f) 2>/dev/null
		fi
	elif [ "$protocol" = "novnc" ]; then
		if [ $enc -eq 1 ]; then
			echo -n "Starting encrypted NOVnc connection..."
			url="https://$targetNodeIp:$targetNodePort"
		else
			echo -n "Starting clear NOVnc connection..."
			url="http://$targetNodeIp:$targetNodePort"
		fi
		notify-send -t $timeout -a 'Kubernetes on Desktop' "One time Token" "$token"
		firefox $url &>/dev/null
		pid=`pgrep firefox`
		((timeout=timeout*timeout))
		timeout $timeout tail --pid=$pid -f /dev/null &>/dev/null
	else
		echo -n "Starting encrypted XRDP connection..."
		rdesktop -r sound:local $targetNodeIp:$targetNodePort 2>/dev/null
	fi
	echo "OK"
}

#Retrieving the IP/port of the node
function retrieve_pod_info {
	targetNodeIp=`kubectl get pod -l app=${application_name} -o "jsonpath={..status.hostIP}"`
	targetNodePort=`kubectl get svc ${application_name}-service -o 'jsonpath={.spec.ports[?(@.name=="'${protocol}'-svc-port")].nodePort}'`
}

#Main function to start the deployment of the desired application
function start_deploy {
	#For safety let's copy the deployment and modify the temporary one
	tmp_name="$(date +%F_%T).yaml"
	cp ${targetDeploy} ./${tmp_name}
	targetDeploy="$tmp_name"

	#Register Ctr+C interrupt
	trap clear_and_exit INT TERM
	
	adjust_screen && adjust_encription && adjust_appname && adjust_protocol
	
  #Checking connectivity
  #To perform that task, the command `kubectl describe pods` is used (we could use version, but too fast since tight)
  echo -n "Checking connectivity..."
  nettime=$( TIMEFORMAT="%3U + %3S"; { time timeout 2 kubectl describe pods; } 2>&1)

  if [ $? -eq 0 ]; then
  	#Parsing previous output to get sum of seconds
  	nettime=$(echo ${nettime} | sed 's/,/./g' |  awk '{printf "%f", $1 + $2}')
		
		#Checking network speed availability
		if [[ $(echo "${nettime}<${connection_answer_time}" | bc) -eq 1 ]]; then
			
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
				deployed=1
				
				#Waiting for the pod to start
				echo -n "Waiting for pod to start, max ${timeout}seconds..."
				kubectl wait --for=condition=Ready pod -l "app=${application_name}" --timeout=${timeout}s &>/dev/null
	
				if [ $? -eq 0 ]; then
					echo "OK pod running"
					
					echo -n "Retrieving node IP and PORT..."
					retrieve_pod_info
					echo "OK ${targetNodeIp}:${targetNodePort}"
					
					echo -n "Waiting for the NodePort to be opened..."
					timeout $timeout bash -c "while ! nc -z $targetNodeIp $targetNodePort; do sleep 1;done"

					if [ $? -eq 0 ]; then
						echo "OK port opened"
						connect
						return

					else
						echo "ERROR Nodeport took too much to be opened, running ${application_name} locally"
					fi
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
		echo "ERROR no Internet, running ${application_name} locally"
  fi
	${application_name} &>/dev/null &
}

#Delete only the deployment NOT the volume
function clear_and_exit {
	echo
	if [ $deployed -eq 1 ]; then
		echo -n "Deleting deploy on cluster..."
		kubectl delete -f $targetDeploy &>/dev/null
		echo "OK"
	fi
	echo -n "Deleting deploy file..."
	rm -f $targetDeploy
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

#Retrieve user screen dimensions
function retrieve_screen_dim {
	echo -n "Reading screen dimensions...OK "
	read -r width height <<<$(xdpyinfo | grep -w -m 1 "dimensions" | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/' | sed 's/x/ /g')
	echo "${width}x${height}"
}

#Function to retrieve each parameter interactively (STILL NOT COMPLETED
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
	asd=1
	if [ $# -lt 1 ] || ! ( IFS=$'\n'; echo "${supported_apps[*]}" ) | grep -qFx "$application_name" &>/dev/null; then
		print_usage_and_exit 1
	fi

	retrieve_screen_dim &>/dev/null

	while getopts "ihd:etp:" opt; do
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
			p)
				if ! ( IFS=$'\n'; echo "${supported_protocols[*]}" ) | grep -qFx "$OPTARG" &>/dev/null; then
					echo "Protocol not supported"
					exit 1
				fi
				protocol="$OPTARG"
				echo "Parameter PROTOCOL $OPTARG...OK"
				if [ "$OPTARG" = "xrdp" ] && [ "$application_name" = "firefox" ]; then
					application_name="${application_name}-xrdp"
				fi
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