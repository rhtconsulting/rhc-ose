#!/bin/bash

# 
# Create a base image for OpenShift Enterprise 3
#

#
# Prerequisite:
#  - run as "root" (or a user with "root" level access")
#  - execute on a system with libvirt/virt-mangaer installed
#  - ensure that enough space is available in /tmp (2GB+) for image creation
#  - have a valid RHN username/password + a pool id available
#
# Instructions to run:
#  >> source <path to OpenStack rc file>
#    - where <path to OpenStack rc file> is the rc file for glance to communicate with OpenStack
#  >> bash ./create_base_img.sh -i=<path_to_iso>
#    - where <path_to_iso> is the path to the installation ISO for RHEL 7.x 
#
#
# NOTE: this script attempts to install any "missing" dependencies to the hosting system

#
# CONSTANTS
#
DISKSIZE=20G
IMAGE_NAME="ose3-base"
VM_PREFIX="ose3"
SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


#
# GLOBALS
#
TmpDir=`mktemp -d`
TmpName=`date +%s`
FinalName=`date +%Y-%m-%d-%H%M`

declare -A RHN



#
# FUNCTIONS
#


function usage()
{
  echo "Usage: "
  echo "  $0 -i <iso>"
  echo ""
  echo "  where:"
  echo "    -i|--iso   : Location of source ISO for installation"
  echo ""
}


function runCmd()
{
  cmd=${1}
  errMsg=${2}

  ${cmd} &>/dev/null

  rc=$?  
  [ ${rc} -ne 0 ] && echo "${errMsg} - rc=${rc}" && exit 1  
}


function obtainRHNdetails()
{
  echo "This tool will run RHN subscription-manager."
  echo "Please provide your RHN username/password, and a subscription pool id, when prompted."
  echo "Please exit now (ctrl+c) if you don't have this information available."

  i=9
  while [ $i -gt 0 ]
  do
    echo -ne "  ${i} ...\033[0K\r"
    i=$((i-1))
    sleep 1
  done

  echo
  echo -n "RHN Username: "
  read RHN['username']

  echo -n "RHN password: "
  read -s RHN['password']
  echo

  echo -n "RHN pool id: "
  read RHN['poolid']

  # Check for prereqs
  if [ -z "${RHN['username']}" ] || [ -z "${RHN['password']}" ] || [ -z "${RHN['poolid']}" ]; then
    echo "Missing some RHN info. Please retry..."
    exit 1
  fi

  echo "Thank you! Proceeding..."
}


function systemCheck()
{
  runCmd 'systemctl status libvirtd' "${FUNCNAME}(): libvirtd not running. Is it installed, enabled and started?"

  runCmd 'yum -y install virt-install libguestfs-tools' "${FUNCNAME}(): failed to install virt-install and libguestfs-tools"

  for i in virt-sysprep mcopy qemu-img virt-install virsh glance 
  do
    runCmd "which ${i}" "${FUNCNAME}(): The command '${i}' is not found. Is it installed?"
  done
}


function createFloppyImage()
{
  runCmd "cp ${SCRIPT_BASE_DIR}/ks.cfg ${TmpDir}/ks.cfg" "${FUNCNAME}(): cp of ks.cfg file failed"

  sed -i -e "s/_KS_RHN_USERNAME_/${RHN['username']}/" ${TmpDir}/ks.cfg 
  sed -i -e "s/_KS_RHN_PASSWD_/${RHN['password']}/" ${TmpDir}/ks.cfg 
  sed -i -e "s/_KS_RHN_POOL_ID_/${RHN['poolid']}/" ${TmpDir}/ks.cfg 

  runCmd "dd bs=512 count=2880 if=/dev/zero of=${TmpDir}/floppy.img" "${FUNCNAME}(): dd failed"
  runCmd "mkfs.vfat ${TmpDir}/floppy.img" "${FUNCNAME}(): mkfs.vfat failed"
  runCmd "mcopy -i ${TmpDir}/floppy.img ${TmpDir}/ks.cfg ::ks.cfg" "${FUNCNAME}(): mcopy failed"
  runCmd "rm ${TmpDir}/ks.cfg" "${FUNCNAME}(): rm of ks.cfg failed"
}


function prepForInstall()
{
  runCmd "qemu-img create -f qcow2 ${TmpDir}/${IMAGE_NAME}.qcow2 ${DISKSIZE}" "${FUNCNAME}(): qemu-img create failed"
  runCmd "chmod 755 ${TmpDir}" "${FUNCNAME}(): chmod 755 ${TmpDir} failed"
  runCmd "chmod 666 ${TmpDir}/${IMAGE_NAME}.qcow2" "${FUNCNAME}(): chmod 666 ${TmpDir}/${IMAGE_NAME}.qcow2 failed"
}



function install()
{
  source_iso=${1}

  virt-install \
      --virt-type kvm \
      --name "${VM_PREFIX}_${TmpName}" \
      --ram 1024 \
      --disk ${TmpDir}/${IMAGE_NAME}.qcow2 \
      --disk ${TmpDir}/floppy.img \
      --network network=default \
      --os-type=linux \
      --os-variant=rhel7 \
      --location ${source_iso} \
      --extra-args="inst.sshd inst.ks=hd:vdb:/ks.cfg" \
      --noreboot \
      --noautoconsole \
      --wait=-1

  rc=$?
  [ ${rc} -ne 0 ] && echo "${FUNCNAME}(): virt-install failed with rc=${rc}." && exit 1
}


function postInstallSteps()
{
  runCmd "virt-sysprep -d ${VM_PREFIX}_${TmpName}" "${FUNCNAME}(): virt-sysprep failed"
  runCmd "virsh undefine ${VM_PREFIX}_${TmpName}" "${FUNCNAME}(): virsh undefine failed"

  FinalName=`date +%Y-%m-%d-%H%M`
  runCmd "qemu-img convert -c ${TmpDir}/${IMAGE_NAME}.qcow2 -O qcow2 ${TmpDir}/${IMAGE_NAME}-${FinalName}.qcow2" "${FUNCNAME}(): qemu-img convert failed"
  runCmd "qemu-img amend -f qcow2 -o compat=0.10 ${TmpDir}/${IMAGE_NAME}-${FinalName}.qcow2" "${FUNCNAME}(): qemu-img amend failed"

  echo "Successfully created image (${TmpDir}/${IMAGE_NAME}-${FinalName}.qcow2)"
}


function uploadImageToTarget()
{
  glance image-create \
         --name "${IMAGE_NAME}-${TmpName}" \
         --is-public False \
         --progress \
         --human-readable \
         --container-format bare \
         --disk-format qcow2 \
         --file ${TmpDir}/${IMAGE_NAME}-${FinalName}.qcow2

  rc=$?
  [ ${rc} -ne 0 ] && echo "${FUNCNAME}(): glance image-create failed with rc=${rc}." && exit 1
}


function cleanup()
{
  runCmd "rm -rf ${TmpDir}" "${FUNCNAME}(): rm -rf failed"
}



#
# MAIN - main execution starts below
#

for i in "$@"
do
  case $i in
    -i=*|--iso=*)
      SourceISO="${i#*=}"
      shift
    ;;

    -h|--help)
      usage
      exit 0
    ;;

    *)
      echo "Invalid Option: ${i#*=}"
      exit 1;
    ;;

  esac
done

if [ -z "${SourceISO}" ]
then
  echo "Missing required args"
  usage
  exit 1
fi

obtainRHNdetails
systemCheck
createFloppyImage
prepForInstall
install "${SourceISO}"
postInstallSteps
uploadImageToTarget
cleanup

exit 0
