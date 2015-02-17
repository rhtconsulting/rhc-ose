#!/bin/bash
SCRIPT_URL="https://raw.githubusercontent.com/openshift/openshift-extras/enterprise-2.2/enterprise/install-scripts/generic/openshift.sh"

usage() {
  echo "Usage: $0 --key [openstack ssh key name] --rhsm_user [rhsm-username] --rhsm_pass [rhsm-password] --roles [roles]"
  echo "  Currently Supported Roles:
    - broker
    - node"
}

random_password() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-16} | head -n 1
}

## Process options
while [[ $# -gt 0 ]] &&  [[ ."$1" = .--* ]] ;
do
  opt=$1
  shift
  case "$opt" in
    "--" ) break 2;;
    "--key" )
      key="$1"; shift;;
    "--rhsm_user")
      rhsm_username="$1"; shift;;
    "--rhsm_pass")
      rhsm_password="$1"; shift;;
    "--roles")
      roles="$1"; shift;;
    *) echo >&2 "Invalid option: $@"; exit 1;;
  esac
done

if [ -z $key ] || [ -z $rhsm_username ] || [ -z $rhsm_password ] || [ -z "$roles" ]; then
  echo "Missing argument."
  usage
  exit 1;
fi

## First, create an instance
#TODO: this
echo "Creating Instance and Waiting for it to become available"
instance_ip=$(./provision.sh --key ${key} --n)

# need to wait until ssh service comes up on instance
ssh -o StrictHostKeyChecking=no cloud-user@${instance_ip} 'ls' &>/dev/null
until [ $? -eq 0 ]; do
  ssh -o StrictHostKeyChecking=no cloud-user@${instance_ip} 'ls' &>/dev/null
done

## Now Setup Repos
# allow root access to instance
ssh -o StrictHostKeyChecking=no -tt cloud-user@${instance_ip} 'sudo cp -r ~/.ssh/ /root/'

# Run Broker and Node setup scripts
echo "Configuring Repos..."
ssh -o StrictHostKeyChecking=no root@${instance_ip} "bash -s" -- < ../repo_config.sh $rhsm_username $rhsm_password $roles | tee ~/repo-config.log

## Finally, install OSE
echo "Installing OSE..."
demo_password=random_password
ssh -o StrictHostKeyChecking=no root@${instance_ip} "export CONF_OPENSHIFT_PASSWORD1=$demo_password; bash . " < ./openshift.conf ";
curl -o ./openshift.sh ${SCRIPT_URL} && bash ./openshift.sh | tee ~/openshift-install.log;"

echo "Your Instance IP is: ${instance_ip}"
echo "Done"
