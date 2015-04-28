# ose3 Provisioning & Installation scripts

No warranty is offered or implied and use of these scripts may destroy your entire OpenShift environment.

## Semi-automated install (byo VMs)

1. Create VMs (1 master, N nodes) to which you have root access via SSH keys.
2. Run osc-sync-keys to give master SSH access to Nodes
3. Setup DNS on your Master, such that you can refer to all VMs by hostname on any VM.
4. Create a wildcard entry for all applications (i.e. *.cloudapps.example.com) which resolves to the Master
5. Install both MASTER and NODE to master instance ONLY:
```bash
./osc-install --master=mymaster.ose.example.com
```
6. Create your router and docker registry:
```bash
openshift ex router --create
openshift ex registry --create
```
7. Re-run install to add the nodes:
```bash
./osc-install --master=mymaster.ose.example.com --nodes=node1.ose.example.com,node2.ose.example.com,...
```

## Fully Automated Environment Provisioning

See sub-directories for environment specific provisioning scripts and instructions.

Current implementations:

 - Openstack
