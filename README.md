# ose-utils | OpenShift Enterprise 3

Miscellaneous utilities for use with OpenShift Enterprise 3 (currently in beta)

Note that these utilities must be run from a shell command line on a master.

All of the scripts support a --help or -h option that produces slightly useful output.

Note that these scripts all use unpublished internal API's that may be changed with no warning.

No warranty is offered or implied and use of these scripts may destroy your entire OpenShift environment.

## Utility Scripts

 - osc-cleanup-project : Utility script for deleting all resources in a project. Project is selected based current-context on kubeconfig login.

 - docker-registry-sync : Utility used to sync docker images from a public registry to a private registry (useful for enabling disconnected environments)

## Environment Provisioning Scripts

Collection of scripts used for provisioning OpenShift Environments.

See [Provisioning Documentation](provisioning/README.md) for more details.
