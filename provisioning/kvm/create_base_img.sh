#!/bin/bash


#
# GLOBALS
#
DISKSIZE=20G
IMAGE_NAME="ose3-base"
VM_PREFIX="ose3"

#
# Globals
#
TmpDir=`mktemp -d`
TmpName=`date +%s`
FinalName=`date +%Y-%m-%d-%H%M`


function usage()
{
  echo "Usage: "
  echo "  $0 -i <iso>"
  echo ""
  echo "  where:"
  echo "    -i|--iso  : Location of source ISO for installation"

}


function systemCheck()
{
  systemctl status libvirtd &>/dev/null
  [ $? -ne 0 ] && echo "libvirtd not running. Is it installed, enabled and started?" && exit 1

  yum -y install virt-install libguestfs-tools

  for i in virt-sysprep mcopy qemu-img virt-install virsh glance 
  do
    which ${i} &>/dev/null
    [ $? -ne 0 ] && echo "The command '${i}' is not found. Is it installed?" && exit 1  
  done
}

function createFloppyImage()
{
  username=${1}
  password=${2}
  repo_id=${3}

  cp ks.cfg ${TmpDir}/ks.cfg

  sed -i -e "s/_KS_RHN_USERNAME_/${username}/" ${TmpDir}/ks.cfg 
  sed -i -e "s/_KS_RHN_PASSWD_/${password}/" ${TmpDir}/ks.cfg 
  sed -i -e "s/_KS_RHN_POOL_ID_/${repo_id}/" ${TmpDir}/ks.cfg 

  dd bs=512 count=2880 if=/dev/zero of=${TmpDir}/floppy.img
  mkfs.vfat ${TmpDir}/floppy.img 
  mcopy -i ${TmpDir}/floppy.img ${TmpDir}/ks.cfg ::ks.cfg
  rm ${TmpDir}/ks.cfg
}


function prepForInstall()
{
  qemu-img create -f qcow2 ${TmpDir}/${IMAGE_NAME}.qcow2 ${DISKSIZE}
  chmod 755 ${TmpDir}
  chmod 666 ${TmpDir}/${IMAGE_NAME}.qcow2
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
  [ ${rc} -ne 0 ] && echo "virt-install failed with rc=${rc}." && exit 1
}


function postInstallSteps()
{
  virt-sysprep -d "${VM_PREFIX}_${TmpName}"
  virsh undefine "${VM_PREFIX}_${TmpName}"

  FinalName=`date +%Y-%m-%d-%H%M`
  qemu-img convert -c ${TmpDir}/${IMAGE_NAME}.qcow2 -O qcow2 ${TmpDir}/${IMAGE_NAME}-${FinalName}.qcow2
  qemu-img amend -f qcow2 -o compat=0.10 ${TmpDir}/${IMAGE_NAME}-${FinalName}.qcow2
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
}


function cleanup()
{
  rm -rf ${TmpDir}
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
read RHN_Username

echo -n "RHN password: "
read -s RHN_Password
echo

echo -n "RHN pool id: "
read RHN_PoolId

# Check for prereqs
if [ -z "${RHN_Username}" ] || [ -z "${RHN_Password}" ] || [ -z "${RHN_PoolId}" ]; then
  echo "Missing some RHN info. Please retry..."
  exit 1
fi

echo "Thank you! Proceeding..."

systemCheck
createFloppyImage "${RHN_Username}" "${RHN_Password}" "${RHN_PoolId}"
prepForInstall
install "${SourceISO}"
postInstallSteps
uploadImageToTarget
cleanup

exit 0
