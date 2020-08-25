#!/bin/bash

#Rebuild existent image [0|1] by removing it before build
reb=0

#Version
ver="latest"

#Push labels
push=()

#Owner name
owner_name="riccardoroccaro"

#Repository name
repo_name="RAR_NOT_DEFINED"

#Supported images
image_pool=( "vncviewer" "base" "firefox" "libreoffice" "blender" )

#Repository pool
declare -A repo_pool
repo_pool[${image_pool[0]}]="vncviewer"
repo_pool[${image_pool[1]}]="base-headless-vnc"
repo_pool[${image_pool[2]}]="firefox-headless-vnc"
repo_pool[${image_pool[3]}]="libreoffice-headless-vnc"
repo_pool[${image_pool[4]}]="blender-headless-vnc"

#Dockerfile args and paths
declare -A df_args_paths
df_args_paths[${image_pool[0]}]="./vncviewer"
df_args_paths[${image_pool[1]}]="./vncserver/base_image"
df_args_paths[${image_pool[2]}]="--build-arg APPLICATION=${image_pool[2]} ./vncserver/app_image"
df_args_paths[${image_pool[3]}]="--build-arg APPLICATION=${image_pool[3]} ./vncserver/app_image"
df_args_paths[${image_pool[4]}]="--build-arg APPLICATION=${image_pool[4]} --build-arg REPO_TO_ADD=ppa:thomas-schiex/blender ./vncserver/app_image"

function print_usage_and_exit {
    echo "Build specified image and push it in DokerHub."
	echo "Usage: $this_app_name [-h] [-r] [-v <build version>] [-p <push version>] -i <image>"
	echo "|-> -h: start the helper menu"
    echo "|-> -r: rebuild image by removing the existing one (if any() and building it again"
    echo "|-> -v: specify the current build version. If not set $ver will be used"
    echo "|-> -p: push the specified image version on DockerHub. It is possible to specify more than one version, one for each -p option."
    echo "|       In any cases, the built image will be tagged with that versions and pushed on DockerHub"
    echo "|-> -i: (MANDATORY) the image to build. Supported images: $(IFS=','; echo "${image_pool[*]}")"
    echo "|"
	echo "|->Example: $this_app_name -i firefox"
    echo "|->Example: $this_app_name -v v1.0 -i base"
    echo "|->Example: $this_app_name -v v2.0 -p v2.0 -p stable -p latest -i vncviewer"
    echo "|           in this case the image with version v2.0 will be tagged with 'stable' and 'latest' versions and all that three"
    echo "|           will be pushed on DockerHub"

    exit $1
}

function image_rebuild {
    #Check whether the image exists or not
    sudo docker inspect $image_name:$ver &>/dev/null
    if [[ $? == 0 ]]; then
        echo "The image already exists, it will be removed and rebuilt"
        echo -n "Removing existing image..."
        sudo docker image rm $image_name:$ver &>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: cannot remove existing image. Exiting..."
            exit 4
        else
            echo "Done"
        fi
    fi
}

function tag_and_push_images {
    for v_tag in ${push[@]}; do
        #Tagging the image
        if [[ $ver != $v_tag ]]; then
            echo -n "Tag version $v_tag..."
            sudo docker tag $image_name:$ver $image_name:$v_tag &>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error: cannot tag the image. Exiting..."
                exit 6
            else
                echo "Done"
            fi
        fi

        #Pushing the image
        echo "Pushing version $v_tag..."
        sudo docker push "$image_name:$v_tag"
        if [ $? -ne 0 ]; then
            echo "Error: cannot push the image. Exiting..."
            exit 7
        else
            echo "Done"
        fi
    done
}

function retrieve_image_to_build {
    for image in ${image_pool[*]}; do
        if [[ $1 == $image ]]; then
            echo "Set image $image to be built"

            #Set the repository name
            repo_name=${repo_pool[$image]}

            #Create the image tag string
            image_name=$owner_name"/"$repo_name

            #Create the args and dockerfile path string
            docker_file_arg_path=${df_args_paths[$image]}

            return
        fi
    done

    #Image not supported
    echo "Error: image $1 not supported"
    print_usage_and_exit 2
}

function main {
    #Retrieve this app name
    this_app_name=$0

    while getopts "hrv:p:i:" opt; do
        case $opt in
            h)  #Print usage and exit
                print_usage_and_exit 0
                ;;
            r)  #Remove image if it already exists and build it again
                reb=1
                echo "Set option 'rebuild forcing previous image remove'"
                ;;
            v)  #Version to build
                ver=$OPTARG
                echo "Set image version $ver to be built"
                ;;
            p)  #Retrieve push versions
                push+=($OPTARG)
                echo "Set image version $OPTARG to be pushed"
                ;;
            i)  #Retrieve image to build
                retrieve_image_to_build $OPTARG
                ;;
            \?) #Option unsupported
                echo "Error: unsupported option"
                print_usage_and_exit 1
                ;;
        esac
    done

    if [[ $repo_name == "RAR_NOT_DEFINED" ]]; then
        echo "Error: image to build not set."
        print_usage_and_exit 3
    fi

    if [ $reb -eq 1 ]; then
        image_rebuild
    fi

    #Building the docker image
    echo "Building the docker image..."
    sudo docker build -t "$image_name:$ver" $docker_file_arg_path
    if [ $? -ne 0 ]; then
        echo "Error: cannot create the image. Exiting..."
        exit 5
    else
        echo "Done"
    fi

    #Check if there are images to be pushed
    if [ ${#push[@]} -gt 0 ]; then
        tag_and_push_images
    fi

    exit 0
}

main $@
