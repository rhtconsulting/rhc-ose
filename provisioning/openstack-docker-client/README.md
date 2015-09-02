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

## Troubleshooting

Below are some of helpful hints for resolving issues experiencing while configuring and running the container

**Issue #1 **

```
$ ./run.sh 
time="2015-09-01T11:22:05-04:00" level=fatal msg="Get http:///var/run/docker.sock/v1.18/images/json: dial unix /var/run/docker.sock: no such file or directory. Are you trying to connect to a TLS-enabled daemon without TLS?" 
Building Docker Image rhtconsulting/rhc-openstack-client....
Sending build context to Docker daemon 
FATA[0000] Post http:///var/run/docker.sock/v1.18/build?cgroupparent=&cpusetcpus=&cpushares=0&dockerfile=Dockerfile&memory=0&memswap=0&rm=1&t=rhtconsulting%2Frhc-openstack-client: dial unix /var/run/docker.sock: no such file or directory. Are you trying to connect to a TLS-enabled daemon without TLS? 
```

**Resolution #1**

Verify the Docker service is running

**Issue #2**

```
./run.sh
Building Docker Image rhtconsulting/rhc-openstack-client....
...
/root/start.sh: line 14: /root/.openstack/*.sh: No such file or directory
cp: cannot stat '/root/ssh/id_rsa': No such file or directory
chmod: cannot access '/root/.ssh/id_rsa': No such file or directory
/root/start.sh: line 29: /root/.openstack/*.sh: No such file or directory
```

**Resolution #2**

This error indicates the Docker container is unable to access files on the host. This can occur due to permission issues accessing files owned by the a user when docker is run using another user. 

To resolve this issue, create a new *docker* group and add the user to the *docker* group

```
groupadd docker
usermod -a -G docker ${USER}
systemctl enable docker
systemctl start docker
```

Reboot the machine to complete the configurations