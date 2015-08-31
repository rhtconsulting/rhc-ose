#!/bin/bash

# start.sh - Helper script that is executed when the Docker container is started up to arrange files in the proper locations

SSH_DIR=/root/ssh

# Attempt to source files for OpenStack
if [ -d ~/.openstack/ ]; then

	FILES=~/.openstack/*.sh
	
	for file in $FILES
	do
		source $file
	done

fi

# Move Docker Volume
if [ -d $SSH_DIR ]; then

	mkdir -p ~/.ssh
	
	cp -f $SSH_DIR/id_rsa ~/.ssh/
	chmod 600 ~/.ssh/id_rsa
	
	for file in $FILES
	do
		source $file
	done

fi

exec "$@"
