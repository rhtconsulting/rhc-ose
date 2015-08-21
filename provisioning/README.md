# ose3 Provisioning & Installation scripts

No warranty is offered or implied and use of these scripts may destroy your entire OpenShift environment.

## Semi-automated install (byo VMs)

1. Create VMs (1 master, N nodes) to which you have root access via SSH keys.
2. Run osc-sync-keys from your local machine to give master SSH access to Nodes
```bash
[me@localhost]$ ./osc-sync-keys --master="<master ip>" --nodes="<node1 ip>,<node2 ip>,...,<nodeN ip>"
```
3. Log into your master and clone the repository
```bash
[me@localhost]$ ssh root@<master ip>
[root@<master>]# git clone git@github.com:redhat-consulting/ose-utils.git
```
4. Run the installer.
```bash
[root@<master>]# ./osc-install --master="<master private ip>|<master public ip>" --nodes="<node1 private ip>|<node1 public ip>,...,<nodeN private ip|nodeN public ip>" --actions=prep,dns,install,post
```

You'll need to create you openshift router and registry (see https://github.com/openshift/training/) once the installation finishes.

## Fully Automated Environment Provisioning

We now support full end-to-end Environment Provisioning.

Current implementations:

 - Openstack

### Instructions

1. [Configure client tools](provisioning/openstack/README.md)
2. Clone this repo.
3. Run provisioning script:
```bash
# Run osc-provision with no options to show Usage output and options
$ [esauer@eric-laptop ose-utils]$ ./provisioning/osc-provision
Missing argument: --num-nodes <integer>

Usage: ./provisioning/osc-provision --num-nodes=<integer> [options]

Options:
--openshift-domain=<domain>   : Base domain name for your OpenShift environment (default: ose.example.com)
--cloudapp-domain=<domain>    : Wildcard domain for your applications (default: *.ose.example.com)
--master-is-node              : Master will also be provisioned as a node (set to false if not passed)
--no-install                  : Provision instances and sync keys, but do not run the OpenShift installer
--key=<key name>              : SSH Key used to authenticate to Cloud API
--debug                       : Will add -x to all bash commands

# Minimal environment provisioning command
$ ./ose-utils/provisioning/osc-provision --num-nodes=2 --key=laptop-key
```
