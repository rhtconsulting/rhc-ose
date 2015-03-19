## Getting Started ##
 * Get Access to OS1: https://mojo.redhat.com/docs/DOC-28082#jive_content_id_Getting_Started
 * Install nova client package
 ```bash
 yum install python-novaclient
 ```
 * Log into the OpenStack Dashboard
 * Navigate to Compute > Access & Security > API Access and click to "Download OpenStack RC File"
 * Place rc file in openstack directory

 ```bash
 mkdir ~/.openstack
 mv ~/Downloads/Consulting\ Middleware\ Delivery-openrc.sh ~/.openstack/openrc.sh
 ```
 * Add your password to the rc file so that
 ```bash
 echo "Please enter your OpenStack Password: "
 read -sr OS_PASSWORD_INPUT
 export OS_PASSWORD=OS_PASSWORD_INPUT
 ```

 becomes

 ```bash
 export OS_PASSWORD=mypassword
 ```


## Create an Instance and Installing OpenShift ##
 * Run the OpenShift Install script

 ```bash
 ./install-ose.sh --key [openstack ssh key name] --rhsm_user [rhsm-username] --rhsm_pass [rhsm-password] --roles "broker node"
 ```

### Notes ###
- currently only supports all-in-one install
