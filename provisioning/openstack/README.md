# ose3 OpenStack Provisioning

## Client Tools Setup ##
1. Get Access to an OpenStack Cloud Environment
1. Log into the OpenStack Dashboard
1. Navigate to Compute > Access & Security > API Access and click to "Download OpenStack RC File"
1. Place rc file in openstack directory
```bash
mkdir ~/.openstack
mv /path/to/openstack/rc.sh ~/.openstack/openrc.sh
```
1. Add your password to the rc file so that
```bash
echo "Please enter your OpenStack Password: "
read -sr OS_PASSWORD_INPUT
export OS_PASSWORD=OS_PASSWORD_INPUT
```
becomes
```bash
export OS_PASSWORD=mypassword
```
NOTE: We will be switching to tokenized auth as soon as its supported in our environment, so as not to require storing passwords in text files.
1. Install Openstack client packages
 * Option 1 (recommended): Setup the [OpenStack Docker Client](/docker/openstack-docker-client)
 * Option 2: Install the nova client tools to your local machine.  Instructions can be found [here]( http://docs.openstack.org/user-guide/common/cli_install_openstack_command_line_clients.html#installing-from-packages).

## Create an Instance ##
* Run the OpenShift Install script

```bash
./provision.sh --instance-name <name> --key <key name> [options]
```
