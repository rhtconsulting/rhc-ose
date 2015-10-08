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

# Move Docker Volume
if [ ! -d $SSH_DIR ]; then

	mkdir -p $SSH_DIR
	
	cp -f $INPUT_SSH_DIR/* $SSH_DIR/
	
	if [ -f $SSH_DIR/id_rsa ]; then

		# Change permission of default private key
		chmod 600 $SSH_DIR/id_rsa
	fi

fi

exec "$@"
