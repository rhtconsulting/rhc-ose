OpenStack Docker Client
==================

Produces a container capable of acting as a client for OpenStack

## Setup

The following steps are required to run the docker client.

1. Install docker
  1. on RHEL/Fedora: ```{yum/dnf} install docker```
  2. on Windows: [Install Docker for Windows](https://docs.docker.com/windows/step_one/)
  3. on OSX: [Max OS X](https://docs.docker.com/installation/mac/)
  4. on all other Operating Systems: [Supported Platforms](https://docs.docker.com/installation/)
2. Give your user access to run Docker containers (this is only required in Linux/Unix distros)
```
groupadd docker
usermod -a -G docker ${USER}
systemctl enable docker
systemctl restart docker
```


## Running

The process of creating and running the docker container is facilitated through the ```run.sh``` script inside this repository.  

It will produce the docker image based on a *Dockerfile* and run the docker container based on the following parameters:

```
$ ./provisioning/openstack-docker-client/run.sh --help

     Usage: ./provisioning/openstack-docker-client/run.sh [options]
     Options:
     --configdir=<configdir>       : Directory containing Openstack configuration files (Default: ~/.openstack/)
     --name=<name>                 : Name of the assembled image (Default: rhc-openstack-client)
     --keep                        : Whether to keep the the container after exiting
     --ssh=<ssh>                   : Location of SSH keys to mount into the container (Default: ~/.ssh)
     --repository=<repository>     : Directory containing a repository to mount inside the container
     --help                        : Show Usage Output
```

The script can be run as is with  ```run.sh``` which will create a new image if one was not created previously and then start the container.

## Customizing the parameters

Executing the ```run.sh``` script with no arguments will provide a bare container with the openstack client tools installed. This is great if all you want to do is run manual `nova` commands, but in order to make this more useful, you'll need to pass some parameters to share resources from your local environment. The following parameters can be configured to customize the behavior of the container environment.

### OpenStack Configuration Files

As part of the [OpenStack client configuration](provisioning/openstack/README.md), a client configuration file was downloaded from OpenStack and placed in the ```~/openstack``` directory. When the docker container is started, this directory is mounted inside the container and all ```*.sh``` files are sourced to allow the client to obtain the API endpoint and authentication details.

You can choose to provide an alternate location by using the ```--configdir``` parameter of the ```run.sh``` script

### Repository Content & Scripts

If you are using a repository or some other source folder containing scripts that you would like to have mounted in the container, the ```--repository``` option can be passed which will mount a folder in the container at ```/root/repository```.

### SSH Keys

Since the interaction with OpenStack typically requires the use of SSH communication, the private key from the logged in users running the Docker container will be copied to the containers' ```~/.ssh``` folder. You can choose to modify the default source location by providing the ```--ssh``` option with a reference to the directory  

## Troubleshooting

Below are some of helpful hints for resolving issues experiencing while configuring and running the container

**Issue #1**

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
time="2015-09-01T11:32:36-04:00" level=fatal msg="Get http:///var/run/docker.sock/v1.18/images/json: dial unix /var/run/docker.sock: permission denied. Are you trying to connect to a TLS-enabled daemon without TLS?"
Building Docker Image rhtconsulting/rhc-openstack-client....
Sending build context to Docker daemon
FATA[0000] Post http:///var/run/docker.sock/v1.18/build?cgroupparent=&cpusetcpus=&cpushares=0&dockerfile=Dockerfile&memory=0&memswap=0&rm=1&t=rhtconsulting%2Frhc-openstack-client: dial unix /var/run/docker.sock: permission denied. Are you trying to connect to a TLS-enabled daemon without TLS?
Starting OpenStack Client Container....
FATA[0000] Post http:///var/run/docker.sock/v1.18/containers/create: dial unix /var/run/docker.sock: permission denied. Are you trying to connect to a TLS-enabled daemon without TLS?
```

**Resolution #2**

This error indicates the currently logged in user is unable to access the docker socket.

To resolve this issue, create a new *docker* group and add the user to the *docker* group

```
groupadd docker
usermod -a -G docker ${USER}
systemctl enable docker
systemctl restart docker
```

Reboot the machine or log out/log in to reload your environment and complete the configurations.

**Issue #3**

This is likely a somewhat unique situation whereas the Docker Container is uanble to contact hosts while you are connected to the VPN (i.e. connecting to OS1 internal).  The issue may manifest itself in different ways, but you should be able to validate whether or not you have an issue by executing a simple ping of control.os1.phx2.redhat.com

If you happen to configure your VPN per the MOJO recommendation (DOC-973196), it suggests using libreswan.  You should instead use the Cisco Compatible VPN client which will use a tun0 device to connect (rather than attaching the VPN IP directly to the primary interface).

```
$  ping -c 2 10.3.0.3
PING 10.3.0.3 (10.3.0.3) 56(84) bytes of data.

--- 10.3.0.3 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 999ms
$ ip r s
default via 192.168.0.1 dev wlp4s0  proto static  metric 600 
10.0.0.0/8 via 192.168.0.1 dev wlp4s0  src 10.10.53.185 <<<<===--
66.187.233.55 via 192.168.0.1 dev wlp4s0  proto static  metric 600 
172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.42.1 
192.168.0.0/24 dev wlp4s0  proto kernel  scope link  src 192.168.0.207 
192.168.0.0/24 dev wlp4s0  proto kernel  scope link  src 192.168.0.207  metric 600 
192.168.122.0/24 dev virbr0  proto kernel  scope link  src 192.168.122.1 

```

**Resolution #3**
You will need to install the Cisco Compatiable VPN client and then recreate your VPN connection to RDU (or wherever you connect)

```
$  yum -y install NetworkManager-vpnc-gnome NetworkManager-vpnc NetworkManager-openvpn NetworkManager-openvpn-gnome
```

Recreate your VPN connection and connect.
```
$ ping -c 2 10.3.0.3
PING 10.3.0.3 (10.3.0.3) 56(84) bytes of data.
64 bytes from 10.3.0.3: icmp_seq=1 ttl=59 time=83.6 ms
64 bytes from 10.3.0.3: icmp_seq=2 ttl=59 time=84.2 ms

--- 10.3.0.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 83.688/83.972/84.256/0.284 ms

$ ip r s
default via 192.168.0.1 dev wlp4s0  proto static  metric 600 
10.0.0.0/8 dev tun0  proto static  scope link  metric 50  <<<<===--
66.187.233.55 via 192.168.0.1 dev wlp4s0  proto static  metric 600 
172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.42.1 
192.168.0.0/24 dev wlp4s0  proto kernel  scope link  src 192.168.0.207 
192.168.0.0/24 dev wlp4s0  proto kernel  scope link  src 192.168.0.207  metric 600 
192.168.122.0/24 dev virbr0  proto kernel  scope link  src 192.168.122.1 
```

