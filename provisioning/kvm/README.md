# KVM based tools for ose-utils

*NOTE: these tools are meant to be used to manage/modify/generate KVM based images. If the system used to run these tools do not meet the minimum software requirements, the tools may install the necssary software packages and hence modify the hosting system.*

### Building a KVM based qcow2 image (for use with OpenStack)

**_create_base_img.sh_**

**Prerequisite:**
 - run as "root" (or a user with "root" level access")
 - execute on a system with libvirt/virt-manager installed
 - for a successfully upload to "OpenStack/Glance", make sure the "glance" client is installed and 100% functional
 - also make sure the following tools are installed and functional: virt-sysprep mcopy qemu-img virt-install virsh
 - ensure that enough space is available in /tmp (2GB+) for image creation
 - have a valid RHN username/password + a pool id available (the tool will prompt for the details)
 - with the current version of the tool the full RHEL 7.x DVD ISO _must_ be used

**Instructions to run:**
 - source \<path to OpenStack rc file\>
  - where \<path to OpenStack rc file\> is the rc file for glance to communicate with OpenStack
 - bash ./create_base_img.sh -i=\<path_to_iso\>
  - where \<path_to_iso\> is the path to the installation ISO for RHEL 7.x

For example:
```
# source ~/.openstack/openrc.sh
# bash ./create_base_img.sh -i=/opt/sw/rh/rhel/7/1/rhel-server-7.1-x86_64-dvd.iso
```

**_ks.cfg_**

This is the kickstart file used to generate the image file. If anything different is needed for your image needs, feel free to modify this ks.cfg to your liking before running the *create_base_img.sh* script. For more information about RHEL 7.x and kickstart, take a look here:
https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/chap-kickstart-installations.html

