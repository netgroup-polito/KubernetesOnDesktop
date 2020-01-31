#!/bin/bash

#Quality level for the connection
quality=4
#Compression level
compression=3
#Protocol to be used (default VNC)
protocol="vnc"
#Timeout to wait for the pod creation (expressed in seconds)
timeout=60
#Seconds for the server response to consider a good connection
connection_answer_time=1
#The Persistent Volume Claim deployment
pvcDeploy="kubernetes/volume.yaml"
#The target deployment file
targetDeploy="kubernetes/deployment_audio.yaml"
#Variable to select connection type, 0=clear, 1=encrypted
enc=0
#Variable which tracks if the deployment has successfully been launched
deployed=0
#Pulseaudio port
pulsePort=34567
#List of supported apps
supported_apps=("firefox" "libreoffice")
supported_protocols=("vnc" "novnc")

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
	
	if [ $enc -eq 1 ]; then
		sed -i "${from_vnc_service},${till_vnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_vnc_container},${till_vnc_container} {s/^/#/}" ${targetDeploy}
		sed -i "${from_novnc_service},${till_novnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_novnc_container},${till_novnc_container} {s/^/#/}" ${targetDeploy}
	elif [ "$protocol" = "vnc" ]; then
		sed -i "${from_novnc_service},${till_novnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_novnc_container},${till_novnc_container} {s/^/#/}" ${targetDeploy}
	else
		sed -i "${from_vnc_service},${till_vnc_service} {s/^/#/}" ${targetDeploy}
		sed -i "${from_vnc_container},${till_vnc_container} {s/^/#/}" ${targetDeploy}
	fi
}

#Function to wait for the Nodeport to be opened
function scan_node_port {
	for i in seq 1 $timeout; do
		nc -z $targetNodeIp $targetNodePortSsh
		if [ $? -eq 0 ]; then
			return 0
		fi
	done
	return 1
}

#Retrieving the IP/port of the node
function retrieve_pod_info {
	######## RETRIEVE POD NAME
	targetPodName=`kubectl get pod -l app=${application_name} -o "jsonpath={.items..metadata.name}"`
	targetPodNamespace=`kubectl get pod -l app=${application_name} -o "jsonpath={.items..metadata.namespace}"`
	targetNodeIp=`kubectl get pod -l app=${application_name} -o "jsonpath={..status.hostIP}"`
	targetNodePortProtocol=`kubectl get svc ${application_name}-service -o 'jsonpath={.spec.ports[?(@.name=="'${protocol}'-svc-port")].nodePort}'`
	targetNodePortSsh=`kubectl get svc ${application_name}-service -o 'jsonpath={.spec.ports[?(@.name=="ssh-svc-port")].nodePort}'`
}

#Function to connect to target
function connect {
	# Forwarding sound
	ssh -f -N -R ${pulsePort}:localhost:${pulsePort}  default@${targetNodeIp} -p ${targetNodePortSsh}

	if [ $enc -eq 1 ]; then
		if [ "$protocol" = "vnc" ]; then
			port=5900;
		else
			port=5800;
		fi
		#Creating ssh tunnel for the protocol
		ssh -f -N -L ${port}:localhost:${port}  default@${targetNodeIp} -p ${targetNodePortSsh}
	fi

	if [ "$protocol" = "vnc" ]; then
		#Check encryption, if yes -> start vnc encrypted connection
		#otherwise -> start normal vnc connection
		if [ $enc -eq 1 ]; then
			echo "Starting encrypted VNC connection..."
			target="localhost::${port}"
		else
			echo -n "Starting clear VNC connection..."
			target="$targetNodeIp::$targetNodePortProtocol"
		fi
		vncviewer -CompressLevel $compression -QualityLevel $quality $target -passwd <(echo ${token} | vncpasswd -f) 2>/dev/null
	else
		if [ $enc -eq 1 ]; then
			echo -n "Starting encrypted NOVnc connection..."
			url="http://localhost:$port"
		else
			echo -n "Starting clear NOVnc connection..."
			url="http://$targetNodeIp:$targetNodePortProtocol"
		fi
		notify-send -t 10000 -a 'Kubernetes on Desktop' "One time Token" "$token"
		firefox $url &>/dev/null
		pid=`pgrep firefox`
		((timeout=timeout*timeout))
		
		timeout $timeout "tail --pid=$pid -f /dev/null &>/dev/null"
	fi
	echo "OK"
}

#Main function to start the deployment of the desired application
function start_deploy {
	#For safety let's copy the deployment and modify the temporary one
	tmp_name="$(date +%F_%T).yaml"
	cp ${targetDeploy} ./${tmp_name}
	targetDeploy="$tmp_name"

	#Register Ctr+C interrupt
	trap clear_and_exit INT TERM
	
	adjust_encription && adjust_appname && adjust_protocol
	
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
					echo "OK ${targetNodeIp}, $protocol -> ${targetNodePortProtocol}, ssh -> ${targetNodePortSsh}"
					
					if ! test -f "$HOME/.ssh/id_rsa.pub"; then
						echo "Public ssh key not found, generating new one...";
						ssh-keygen &>/dev/null
						echo "OK"
					fi

					echo -n "Deploying public key to pod..."
					kubectl cp ~/.ssh/id_rsa.pub ${targetPodNamespace}/${targetPodName}:/home/default/.ssh/authorized_keys
					echo "OK"

					echo -n "Loading PulseAudio tcp module..."
					pactl load-module module-native-protocol-tcp port=${pulsePort} auth-ip-acl=::1
					echo "OK"

					echo -n "Waiting for the NodePort to be opened..."
					scan_node_port

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
	if [ $deployed -eq 1 ]; then
		echo -n "Stopping ssh connections..."
		pkill ssh
		echo "OK"
		echo -n "Deleting deploy on cluster..."
		kubectl delete -f $targetDeploy &>/dev/null
		echo "OK"
		echo -n "Unloading PulseAudio TCP module..."
		pactl unload-module module-native-protocol-tcp
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
	echo "|-> -e: specify that the connection must be encrypted (default disabled)"
	echo "|-> -t: connection/wait timeout in seconds (default 60s)"
	echo "|-> -p: connection protocol to be used (default vnc, supports also novnc)"
	echo "|-> -q: specify the quality of the connection (0-9, default 4)"
	echo "|-> -c: specify the compression of the connection (0-6, default 3)"
	echo "|"
	echo "|->Example: ./run_cloud.sh firefox"
	echo "|->Example: ./run_cloud.sh -q 7 -t 10 -e firefox"
	exit $1
}

function main() {
	#Retrieving the name of the application passed as last argument
	for application_name in $@; do :; done
	asd=1
	if [ $# -lt 1 ] || ! ( IFS=$'\n'; echo "${supported_apps[*]}" ) | grep -qFx "$application_name" &>/dev/null; then
		print_usage_and_exit 1
	fi

	while getopts "hec:q:t:p:" opt; do
  	case $opt in
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
	    q)
				if [[ "$OPTARG" =~ ^[0-9]$ ]]; then
					quality=$OPTARG
					echo "Parameter QUALITY...OK ${quality}"
				else
					echo "Parameter QUALITY...INVALID, using default one (${quality})"
				fi
				;;
			c)
				if [[ "$OPTARG" =~ ^[0-6]$ ]]; then
					compression=$OPTARG
					echo "Parameter QUALITY...OK ${compression}"
				else
					echo "Parameter COMPRESSION...INVALID, using default one (${compression})"
				fi
				;;
	    h)
				print_usage_and_exit 0
				;;
			p)
				if ! ( IFS=$'\n'; echo "${supported_protocols[*]}" ) | grep -qFx "$OPTARG" &>/dev/null; then
					echo "Protocol not supported, using the default one (${protocol})"
				else
					protocol="$OPTARG"
					echo "Parameter PROTOCOL $OPTARG...OK"
				fi
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