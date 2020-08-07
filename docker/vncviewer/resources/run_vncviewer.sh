#!/bin/bash
#-----------------------------------------------------------------------------#
#-------------Declare parameters, global variables and constants--------------#
#-----------------------------------------------------------------------------#

###############################################################################
#                                 CONSTANTS                                   #
###############################################################################
###-------------------------------------------------------------------------###
###                   CONST VALUE FOR NOT SET PARAMETERS                    ###
###-------------------------------------------------------------------------###
### Array of the parameters keys                                            ###
PARAM_NOT_SET="not-set"                                                     ###
###-------------------------------------------------------------------------###
###               KEYS OF PARAMS MANDATORY IN ANY USE CASE                  ###
###-------------------------------------------------------------------------###
### Enc param: 0=> clear connection;                                        ###
###            1=> encoded connection                                       ###
PARAM_KEYS+=( "enc" )                  # 0  -> Encoded connection (0/1)     ###
### Pod param: 0=> docker execution;                                        ###  
###            1=> pod execution                                            ###
PARAM_KEYS+=( "pod" )                  # 1  -> Run as a pod (0/1)           ###
### Compression:                                                            ###
###  vnc compression level [0-6]                                            ###
PARAM_KEYS+=( "compression" )          # 2  -> Vnc stream compression       ###
### Quality:                                                                ###
###  vnc quality level [0-9]                                                ###
PARAM_KEYS+=( "quality" )              # 3  -> Vnc video quality            ###
### Target:                                                                 ###
### "targetNodeIp::targetNodePortProt"                                      ###
PARAM_KEYS+=( "target" )               # 4  -> TargetNIp::TargetNPort       ###
### Token: the token passwd                                                 ###
###  to access vnc server                                                   ###
PARAM_KEYS+=( "token" )                # 5  -> Vnc password                 ###
### TargetNodeIp: node IP useful                                            ###
###  to create the ssh tunnel                                               ###
PARAM_KEYS+=( "target_node_ip" )       # 6  -> SSH tunnel target IP         ###
### TargetNodePortSSH: port useful                                          ###
###  to create the ssh tunnel                                               ###
PARAM_KEYS+=( "target_node_port_ssh" ) # 7  -> SSH tunnel target port       ###
###-------------------------------------------------------------------------###
###                 KEY OF PARAMS REQUIRED ONLY IF ENC=1                    ###
###-------------------------------------------------------------------------###
### EncPort: Port to be used for                                            ###
###  encoded ssh connection                                                 ###
PARAM_KEYS+=( "enc_port" )             # 8  -> SSH connection port          ###
###-------------------------------------------------------------------------###
###                 KEY OF PARAMS REQUIRED ONLY IF POD=1                    ###
###-------------------------------------------------------------------------###
### ClientHostIP: the ip of the host in                                     ### 
###  which cloudify runs and the server                                     ###
###  is listening to...                                                     ###
PARAM_KEYS+=( "client_host_ip" )       # 9 -> Cloudify host IP              ###
### ClientHostPort: the port of the                                         ### 
###  host in host in which cloudify                                         ###
###  runs and the server is listening to                                    ###
PARAM_KEYS+=( "client_host_port" )     # 10 -> Cloudify host port           ###
###-------------------------------------------------------------------------###
###                            KEYS SUB-ARRAYS                              ###
###-------------------------------------------------------------------------###
### PARAM Array extraction with all the mandatory parameters keys           ###
PARAM_MANDATORY=${PARAM_KEYS[@]:0:8}                                        ###
### PARAM Array extraction with all the required parameters if enc=1        ###
PARAM_REQUIRED_ENC=${PARAM_KEYS[@]:8:1}                                     ###
### PARAM Array extraction with all the required parameters if pod=1        ###
PARAM_REQUIRED_POD=${PARAM_KEYS[@]:9:2}                                     ###
###-------------------------------------------------------------------------###
###############################################################################

###############################################################################
#                              GLOBAL VARIABLES                               #
###############################################################################
# Declaring the map containing all the key<->value parameters                 #
declare -A PARAMS                                                             #
# Declaring variable to check the app status when it have to terminate        #
state=0                                                                       #
###############################################################################

###############################################################################
#                   HUMAN READABLE CONST MATCHING PARAMS                      #
###############################################################################
enc="PARAMS[${PARAM_KEYS[0]}]"                                                #
pod="PARAMS[${PARAM_KEYS[1]}]"                                                #
compression="PARAMS[${PARAM_KEYS[2]}]"                                        #
quality="PARAMS[${PARAM_KEYS[3]}]"                                            #
target="PARAMS[${PARAM_KEYS[4]}]"                                             #
token="PARAMS[${PARAM_KEYS[5]}]"                                              #
target_node_ip="PARAMS[${PARAM_KEYS[6]}]"                                     #
target_node_port_ssh="PARAMS[${PARAM_KEYS[7]}]"                               #
enc_port="PARAMS[${PARAM_KEYS[8]}]"                                           #
client_host_ip="PARAMS[${PARAM_KEYS[9]}]"                                     #
client_host_port="PARAMS[${PARAM_KEYS[10]}]"                                  #
#                                                                             #
# N.B.:                                                                       #
# Use the variable above as a ref. It means this way ${!<varname>}            #
# Example: to retrieve the enc value use ${!enc}                              #
###############################################################################

#--------End of parameters, global variables and constants declaration--------#

#Function to initialize the application
function init {
    #Initialize the PARAMS map
    for p_key in ${PARAM_KEYS[@]}; do
        PARAMS[$p_key]=$PARAM_NOT_SET
    done
}

#Function to communicate to cloudify that the pod execution is completed
#For authentication purpose and to avoid MITM attacks we also send the token
function close_connection {
nc ${!client_host_ip} ${!client_host_port} <<-EOF 1>&2
    Close_${!token}

EOF
}

#Function to clean up all resources and exit
function clean_and_exit {
    #If enc=1 ane state>=4 ssh vnc tunnel and ssh pulseaudio tunnel are alive => Close the tunnels
    #If enc=0,1 and and state>=3 ssh vnc tunnel is alive => Close the tunnel
    if [[ ${!enc} -eq 1 && $state -ge 4 ]] || [[ $state -ge 3 ]]; then
        echo "Closing ssh PulseAudio and/or VNC tunnel(s) connection..." 1>&2
        ssh -S "${SSH_SOCKET}/ssh_socket:${!target_node_port_ssh}" -O "exit" vncuser@${!target_node_ip} 1>&2
        echo "PulseAudio/VNC tunnel connection closed." 1>&2
    fi

    # If state>=2 PulseAudio TCP module has been already loaded => Unload it
    if [[ $state -ge 2 ]]; then
        echo "Unloading PulseAudio TCP module..." 1>&2
		pactl unload-module module-native-protocol-tcp 1>&2
		echo "OK" 1>&2
    fi

    # If state>=1 PulseAudio daemon is running => Kill it
    if [[ $state -ge 1 ]]; then
        echo "Stopping PulseAudio daemon..." 1>&2
        pkill pulseaudio 1>&2
        echo "OK" 1>&2

    fi

    #If pod=1 => communicate to cloudify that the pod execution is completed
    if [[ ${!pod} -eq 1 ]]; then
        echo "Send pod terminating status to cloudify..." 1>&2
        close_connection
        echo "Terminating sent." 1>&2
    fi

    trap - INT TERM KILL EXIT QUIT HUP

    exit $1
}

#Function to print usage and exit
function print_usage_and_exit {
    echo "Usage: " 1>&2
    echo "|-> Print usage with:  " 1>&2
    echo "|      ./run_vncviewer --help" 1>&2
    echo "|" 1>&2
    echo "|-> Execute with:" 1>&2
    echo "|      ./run_vncviewer ${PARAM_KEYS[0]}=[0|1] \\" 1>&2
    echo "|                      ${PARAM_KEYS[1]}=[0|1] \\" 1>&2
    echo "|                      ${PARAM_KEYS[2]}=[0-6] \\" 1>&2
    echo "|                      ${PARAM_KEYS[3]}=[0-9] \\" 1>&2
    echo "|                      ${PARAM_KEYS[4]}=<IPv4::PORT> \\" 1>&2
    echo "|                      ${PARAM_KEYS[5]}=<string> \\" 1>&2
    echo "|                      ${PARAM_KEYS[6]}=<IPv4> \\" 1>&2
    echo "|                      ${PARAM_KEYS[7]}=[0-65535] \\" 1>&2
    echo "|                      ${PARAM_KEYS[8]}=[0-65535] \\" 1>&2
    echo "|                      ${PARAM_KEYS[9]}=<IPv4> \\" 1>&2
    echo "|                      ${PARAM_KEYS[10]}=[0-65535]" 1>&2
    echo "|" 1>&2
    echo "|-> ${PARAM_KEYS[0]}: MANDATORY! 0=> clear connection; 1=> encoded connection" 1>&2
    echo "|-> ${PARAM_KEYS[1]}: MANDATORY! 0=> docker execution; 1=> pod execution" 1>&2
    echo "|-> ${PARAM_KEYS[2]}: MANDATORY! vnc compression level [0-6]" 1>&2
    echo "|-> ${PARAM_KEYS[3]}: MANDATORY! vnc video quality level [0-9]" 1>&2
    echo "|-> ${PARAM_KEYS[4]}: MANDATORY! targetNodeIp::targetNodePort" 1>&2
    echo "|-> ${PARAM_KEYS[5]}: MANDATORY! the token passwd to access vnc server" 1>&2
    echo "|-> ${PARAM_KEYS[6]}: MANDATORY! Target IP to be used to create ssh tunnels (pulseaudio and/or vnc)" 1>&2
    echo "|-> ${PARAM_KEYS[7]}: MANDATORY! Target port to be used to create ssh tunnel (pulseaudio and/or vnc)" 1>&2
    echo "|-> ${PARAM_KEYS[8]}: REQUIRED IF ${PARAM_KEYS[0]}=1! Port to be used for encoded VNC ssh connection" 1>&2
    echo "|-> ${PARAM_KEYS[9]}: REQUIRED IF ${PARAM_KEYS[1]}=1! IP of the host executing cloudify" 1>&2
    echo "|-> ${PARAM_KEYS[10]}: REQUIRED IF ${PARAM_KEYS[1]}=1! port of the host executing cloudify" 1>&2
    
    #Cleaning allocated resources if any and then exit
    clean_and_exit $1
}

#Function to retrieve and check the parameters
function retrieve_and_check_parameters {
    #Check if there is --help parameter
    if [[ $1 == "--help" ]]; then
        print_usage_and_exit 0
    fi

    #Retrieving the parameters
    for arg in "$@"; do
        
        key=$(echo $arg | cut -f1 -d=)
        val=$(echo $arg | cut -f2 -d=)   
        
        #Check whether $key it's a supported parameter or not and assign its value
        if [[ " ${PARAM_KEYS[@]} " =~ " ${key} " ]]; then
            PARAMS[$key]=$val
            echo "OK! Parameter $key=$val set." 1>&2
        else
            echo "ERR!!! Wrong parameter $key." 1>&2
            print_usage_and_exit 1
        fi
    done

    #Checking mandatory parameters
    for p in ${PARAM_MANDATORY[@]}; do
        if [[ ${PARAMS[$p]} == $PARAM_NOT_SET ]]; then
            echo "Missing parameter $p" 1>&2
            print_usage_and_exit 2
        fi
    done

    #Checking required parameters if enc=1
    if [[ ${!enc} == 1 ]]; then
        for p in ${PARAM_REQUIRED_ENC[@]}; do
            if [[ ${PARAMS[$p]} == $PARAM_NOT_SET ]]; then
                echo "Enc parameter set to 1 => Missing parameter $p" 1>&2
                print_usage_and_exit 3
            fi
        done
    fi

    #Checking required parameters if pod=1
    if [[ ${!pod} == 1 ]]; then
        for p in ${PARAM_REQUIRED_POD[@]}; do
            if [[ ${PARAMS[$p]} == $PARAM_NOT_SET ]]; then
                echo "Pod parameter set to 1 => Missing parameter $p" 1>&2
                print_usage_and_exit 4
            fi
        done
    fi
}

#Function to launch the PulseAudio TCP server
function launch_pulseaudio_server {
    echo "Running PulseAudio as a daemon" 1>&2
    pulseaudio -D 1>&2
    echo "Done" 1>&2
    ((state++))
    # state=1 ; enc=0,1 => pulseaudio is running

    echo -n "Loading PulseAudio tcp module..." 1>&2
    pactl load-module module-native-protocol-tcp port=${PULSE_PORT} auth-ip-acl=127.0.0.1 1>&2
    echo "OK" 1>&2
    ((state++))
    # state=2 ; enc=0,1 => loaded pulseaudio tcp module

    echo -n "Creating PulseAudio ssh tunnel..." 1>&2
    ssh -4 -o UserKnownHostsFile=/dev/null \
        -i "${SSH_ID_RSA}/id_rsa" \
        -oStrictHostKeyChecking=no -f -N \
        -M -S "${SSH_SOCKET}/ssh_socket:${!target_node_port_ssh}" \
        -R ${PULSE_PORT}:localhost:${PULSE_PORT} \
        vncuser@${!target_node_ip} -p ${!target_node_port_ssh} 1>&2
    echo "OK" 1>&2
    ((state++))
    # state=3 ; enc=0,1 => ssh pulseaudio tunnel created
}

#Function to launch vncviewer
function launch_vncviewer {
    #Create ssh tunnel for the vnc protocol if enc=1
    if [[ ${!enc} == 1 ]]; then
        echo "Creating ssh tunnel for the vnc protocol..." 1>&2
        ssh -4 -o UserKnownHostsFile=/dev/null \
            -i "${SSH_ID_RSA}/id_rsa" \
            -oStrictHostKeyChecking=no -f -N \
            -S "${SSH_SOCKET}/ssh_socket:${!target_node_port_ssh}" \
            -L ${!enc_port}:localhost:${!enc_port} \
            vncuser@${!target_node_ip} -p ${!target_node_port_ssh} 1>&2
        echo "Done."
        ((state++))
        # state=4 ; enc=1 => ssh vnc tunnel created
    fi

    #Launch vncviewer
    vncviewer -CompressLevel ${!compression} -QualityLevel ${!quality} \
              ${!target} -passwd <(echo ${!token} | vncpasswd -f) 1>&2
}

function main {
    #Register Ctr+C interrupt
    trap clean_and_exit INT TERM KILL EXIT QUIT HUP

    #Initializing the process
    init

    #Retrieving and checking parameters
    retrieve_and_check_parameters $@

    #Launch pulseaudio server
    launch_pulseaudio_server

    #Launch vncviewer
    launch_vncviewer

    #Cleaning up and exit...
    clean_and_exit 0
}

main $@
