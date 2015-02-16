## Getting Started ##
 * Get Access to OS1: https://mojo.redhat.com/docs/DOC-28082#jive_content_id_Getting_Started
 * Setup euca2ools credentials using the following: https://mojo.redhat.com/docs/DOC-28082#jive_content_id_APICLI_Access
 * Place credentials in ~/.ssh/openstack/ OR set the environment variable OPENSTACK_CRED_HOME

## Creating an Instance ##
 * Create an instance using provision script

  ```bash
  cd [path/to/ose-utils/installation/openstack/]
  ./provision --key [name-of-openstack-ssh-key]
  ```

## Preparing Instance for Configuring ##
 * sync ssh keys

 ```bash
 ssh cloud-user@[instance ip]
 [cloud-user@.... ~] $ sudo cp -r ~/.ssh/ /root/
 [cloud-user@.... ~] $ exit
 ```

## Installing OpenShift ##
 * Run the OpenShift Install script

 ```bash
 ./install-ose.sh
 ```

### Notes ###
- currently only supports all-in-one install
