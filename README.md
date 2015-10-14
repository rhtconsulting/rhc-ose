# rhc-ose | OpenShift Enterprise 3

This repository is a collection of utilities and automation scripts for the management and administration of OpenShift Enterprise 3

See below for more specific documentation of included utilities.

Note that these scripts all use unpublished internal API's that may be changed with no warning.

No warranty is offered or implied and use of these scripts may destroy your entire OpenShift environment.

## Utility Scripts

 - osc-cleanup-project : Utility script for deleting all resources in a project. Project is selected based current-context on kubeconfig login.

 - docker-registry-sync : Utility used to sync docker images from a public registry to a private registry (useful for enabling disconnected environments)

## Environment Provisioning Scripts

Collection of scripts used for provisioning OpenShift Environments.

See [Provisioning Documentation](provisioning/README.adoc) for more details.

## Contributing

See our [Contribution Guide](./CONTRIBUTING.md) for details on how to contribute.
