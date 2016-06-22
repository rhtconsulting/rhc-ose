#!/bin/bash

# Run.sh - Script to build and run a Docker container to facilitate communicate with AWS


SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
AWS_CREDS_FILE=~/.aws_creds
AWS_ENV_CONFIGS=~/.aws_env
AWS_CLIENT_IMAGE="rhtconsulting/aws-client-tools"
SSH_DIR=~/.ssh
REMOVE_CONTAINER_ON_EXIT="--rm"
REPOSITORY=
REPOSITORY_VOLUME=""


usage() {
    echo "
     Usage: $0 [options]
     Options:
     --credsfile=<file>             : File containing AWS API credentials (Default: ~/.aws_creds/)
     --configfile=<file>            : File containing ec2 environment variables (Default: ~/.aws_env)
     --image-name=<name>           : Name of the image to build or use (Default: rhtconsulting/rhc-client-tools)
     --keep                        : Whether to keep the the container after exiting
     --ssh=<ssh>                   : Location of SSH keys to mount into the container (Default: ~/.ssh)
     --repository=<repository>     : Directory containing a repository to mount inside the container
     --help                        : Show Usage Output
	 "
}



# Process Input

for i in "$@"
do
  case $i in
    -c=*|--credsfile=*)
      AWS_CREDS_FILE="${i#*=}"
      shift;;
    -e=*|--configfile=*)
      AWS_ENV_CONFIGS="${i#*=}"
      shift;;
	  -k|--keep)
      REMOVE_CONTAINER_ON_EXIT=""
      shift;;
  	-n=*|--image-name=*)
      AWS_CLIENT_IMAGE="${i#*=}"
      shift;;
    -s=*|--ssh=*)
      SSH_DIR="${i#*=}"
	  shift;;
  	-r=*|--repository=*)
      REPOSITORY="${i#*=}"
      shift;;
    -h|--help)
      usage;
      exit 0;
      ;;
    *)
      echo "Invalid Option: ${i#*=}"
      usage;
      exit 1;
      ;;
  esac
done


if [ ! -f ${AWS_CREDS_FILE} ]; then
	echo "ERROR: AWS configuration files not found! Make sure there is a creds file at ${AWS_CREDS_FILE} or specify a different location"
	exit 1
fi

DOCKER_IMAGES=$(docker images)

if [ $? -ne 0 ]; then
    echo "Error: Failed to determine installed docker images. Please verify connectivity to Docker socket."
    exit 1
fi

AWS_IMAGE=$(echo -e "${DOCKER_IMAGES}" | awk '{ print $1 }' | grep ${AWS_CLIENT_IMAGE})

if [ $? -gt 1 ]; then
  echo "Error: Failed to parse the Docker images to find ${AWS_CLIENT_IMAGE} image."
  exit 1
fi

# Check if Image has been build previously
if [ -z $AWS_IMAGE ]; then
	echo "Building Docker Image ${AWS_CLIENT_IMAGE}...."
	docker build -t ${AWS_CLIENT_IMAGE} ${SCRIPT_BASE_DIR}
fi

# Check if Image has been build previously
if [ ! -z ${REPOSITORY} ]; then

	if [ ! -d ${REPOSITORY} ]; then
		echo "Error: Could not locate specified repository directory"
		exit 1
	fi

	REPOSITORY_VOLUME="-v ${REPOSITORY}:/root/repository:z"

	echo
	echo "Git Repository containing scripts are found and mounted in the '/root/repository' folder"
fi

if [ -d $SSH_DIR ]; then
	SSH_VOLUME="-v ${SSH_DIR}:/mnt/.ssh:z"
else
	echo "Warning: SSH Directory not found"
fi


echo "Starting AWS Client Container...."
echo
if [ -f ${AWS_ENV_CONFIGS} ]; then
  docker run -it ${REMOVE_CONTAINER_ON_EXIT} -v ${AWS_CREDS_FILE}:/root/.aws_creds:z -v ${AWS_ENV_CONFIGS}:/root/.aws_env:z ${REPOSITORY_VOLUME} ${SSH_VOLUME} ${AWS_CLIENT_IMAGE}
else
  docker run -it ${REMOVE_CONTAINER_ON_EXIT} -v ${AWS_CREDS_FILE}:/root/.aws_creds:z ${REPOSITORY_VOLUME} ${SSH_VOLUME} ${AWS_CLIENT_IMAGE}
fi
