OpenStack Docker Client
==================

Produces a container capable of acting as a client for OpenStack

## Running

The process of creating and running the docker container is facilitated through the ```run.sh``` script inside this repository.  

It will produce the docker image based on a *Dockerfile* and run the docker container based on the following parameters:

```
     --configdir=<configdir>       : Directory containing Openstack configuration files (Default: ~/.openstack/)
	 --name=<name>                 : Name of the assembled image (Default: rhtconsulting/rhc-openstack-client)
     --keep                        : Whether to keep the the container after exiting
     --ssh=<ssh>                   : Location of SSH keys to mount into the container (Default: ~/.ssh)
     --repository=<repository>     : Directory containing a repository to mount inside the container

```

The script can be run as is with  ```run.sh``` which will create a new image if one was not created previously and then start the container. 

## Customizing the parameters

The following parameters can be configured to customize the behavior of the execution 

### OpenStack Configuration Files

As part of the [OpenStack client configuration](provisioning/openstack/README.md), a client configuration file was downloaded from OpenStack and placed in the ```~/openstack``` directory. When the docker container is started, this directory is mounted inside the container and all ```*.sh``` files are sourced to allow the client to obtain the API endpoint and authentication details. 

You can choose to provide an alternate location by using the ```--configdir``` parameter of the ```run.sh``` script

### Repository

If you are using a repository or some other source folder that you would like to have mounted in the container, the ```--repository``` option can be passed which will mount a folder in the container at ```/root/repository```

### SSH Keys

Since the interaction with OpenStack typically requires the use of SSH communication, the private key from the logged in users running the Docker container will be copied to the containers' ```~/.ssh``` folder. You can choose to modify the default source location by providing the ```--ssh``` option with a reference to the directory  