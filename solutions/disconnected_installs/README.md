# Scripts for Executing Disconnected Installs

## Quickstart

1. Install a registry server

  ```bash
  yum install -y docker docker-distribution firewalld

  systemctl enable firewalld
  systemctl start firewalld

  firewall-cmd --add-port 5000/tcp --permanent
  firewall-cmd --reload

  systemctl enable docker-distribution
  systemctl start docker-distribution
  ```

2. Run the `docker-registry-sync` script to sync Red Hat images to private registry. Pass in the `openshift-images-*` file that coincides to your version of OpenShift

  ```
  ./docker-registry-sync --from=registry.access.redhat.com --to=<registry-server-ip>:5000 --file=./openshift_images-3.3.1.5
  ```

## Creating Image Lists for new Versions

If an image list for your version of OpenShift does not exist, you can create a new `openshift_images` file with the following process.

This is the file that lists all of the images we are going to sync, and the file contents are specific to the version of OpenShift we are installing. See link:[Official Documentaion on Syncing Images](https://docs.openshift.com/container-platform/latest/install_config/install/disconnected_install.html#disconnected-syncing-images) for the proper image versions to plug in.

Then, run the following commands to create a new file for your install.

```
old_version=3.3.1.5
old_version_hosted=3.3.1
new_version=3.3.1.11 # Plug in version of OpenShift here, without the 'v'
new_version_hosted=3.3.1 # Plug in logging/metrics tag version here
cp openshift_images-${old_version} openshift_images-${new_version}
sed -i "s/${old_version}/${new_version}/g" openshift_images-${new_version}
sed -i "s/${old_version_hosted}/${new_version_hosted}/g" openshift_images-${new_version}
```
