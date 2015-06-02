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

See sub-directories for environment specific provisioning scripts and instructions.

Current implementations:

 - Openstack
