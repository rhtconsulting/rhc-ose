#!/bin/bash

# start.sh - Helper script that is executed when the Docker container is started up to arrange files in the proper locations

SSH_DIR=/root/.ssh
INPUT_SSH_DIR=/root/ssh
CONFIG_DIR=/root/.openstack

# Attempt to source files for OpenStack
if [ -d $CONFIG_DIR ]; then

	FILES=$CONFIG_DIR/*.sh
	
	for file in $FILES
	do
		source $file
	done

fi

exec "$@"
