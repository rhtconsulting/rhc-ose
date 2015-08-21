# ose3 OpenStack Provisioning

## Client Tools Setup ##
* Get Access to OS1: https://mojo.redhat.com/docs/DOC-28082#jive_content_id_Getting_Started
* Install nova client package
```
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
NOTE: We will be switching to tokenized auth as soon as its supported in our environment, so as not to require storing passwords in text files.

## Create an Instance ##
* Run the OpenShift Install script

```bash
./provision.sh --instance-name <name> --key <key name> [options]
```
