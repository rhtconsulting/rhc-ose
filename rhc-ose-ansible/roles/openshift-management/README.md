OpenShift Cluster Administration Role
=============================

This role performs methods to ensure the health and stability of the OpenShift Container Platform Environment

## Management Features

* Pruning Builds
* Pruning Deployments
* Pruning Images

## Required Parameters

The following parameters are required for the execution of this role

`openshift_token` - OAuth Token associated with a user/service account with *cluster-admin* permissions

## Additional Parameters

Each management action has a set of parameters to tailor its' execution. Management actions contained within this role are disabled by default unless explicitly enabled. The following parameters can be configured with a value of `True` ``to enable each management action:

`openshift_prune_builds`  - Pruning builds
`openshift_prune_deployments`  - Pruning deployments
`openshift_prune_images`  - Pruning images in the Integrated Docker Registry

## Running Playbooks with this Role

Prune builds, deployments and images

```
ansible-playbook -e "openshift_token=<token> openshift_prune_builds=True openshift_prune_deployments=True openshift_prune_images=True"
```
