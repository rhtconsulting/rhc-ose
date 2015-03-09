## Getting Started ##
 * Get Access to OS1: https://mojo.redhat.com/docs/DOC-28082#jive_content_id_Getting_Started
 * Setup euca2ools credentials using the following: https://mojo.redhat.com/docs/DOC-28082#jive_content_id_APICLI_Access
 * Place credentials in ~/.ssh/openstack/ OR set the environment variable OPENSTACK_CRED_HOME

## Create an Instance and Installing OpenShift ##
 * Run the OpenShift Install script

 ```bash
 ./install-ose.sh --key [openstack ssh key name] --rhsm_user [rhsm-username] --rhsm_pass [rhsm-password] --roles "broker node"
 ```

### Notes ###
- currently only supports all-in-one install
