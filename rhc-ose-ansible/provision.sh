#!/bin/bash

provision() {
  # Run provision playbook to create the base environment
  ansible-playbook -i ${INVENTORY_FILE} ./ose-provision.yml

  # Grab newly create inventory file
  openshift_inventory=$(ls -Art inventory_* | tail -n 1)

  # Obtain installer path from inventory file
  if [[ -z "${INSTALLER_PATH}" ]]
  then
    INSTALLER_PATH=$(awk -F= "/^openshift_ansible_path=/"'{print $2}' ${openshift_inventory})
  fi

  # Obtain installer playbook from inventory file
  if [[ -z "${INSTALLER_PLAYBOOK}" ]]
  then
    INSTALLER_PLAYBOOK=$(awk -F= "/^openshift_ansible_playbook=/"'{print $2}' ${openshift_inventory})
  fi

  # Run the OpenShift Installer
  echo "Executing: ansible-playbook -i ${openshift_inventory} ${INSTALLER_PATH}/${INSTALLER_PLAYBOOK}"
  ansible-playbook -i ${openshift_inventory} ${INSTALLER_PATH}/${INSTALLER_PLAYBOOK}
}

# Process input
for i in "$@"
do
  case $i in
    --inventory=*|-i=*)
      INVENTORY_FILE="${i#*=}"
      shift;;
    --installer-path=*|-p=*)
      INSTALLER_PATH="${i#*=}"
      shift;;
    --installer-playbook=*|-b=*)
      INSTALLER_PLAYBOOK="${i#*=}"
      shift;;
    --help|-h)
      usage
      exit 0;;
    *)
      echo "Invalid Option: ${i%=*}"
      exit 1;
      ;;
  esac
done

provision
