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

install_ose2() {
  ## First, create an instance
  #TODO: this
  echo "Creating Instance and Waiting for it to become available"
  instance_name="${key}-ose-$(random_password 6)"
  echo "./provision.sh --key ${key} --n --instance-name ${instance_name} ${options}"
  instance_ip=$(./provision.sh --key ${key} --n --instance-name ${instance_name} ${options})

  ## Now Setup Repos
  # allow root access to instance
  ssh -o StrictHostKeyChecking=no -tt cloud-user@${instance_ip} 'sudo cp -r ~/.ssh/ /root/'

  # Run Broker and Node setup scripts
  echo "Configuring Repos..."
  ssh -o StrictHostKeyChecking=no root@${instance_ip} "bash -s" -- < ../repo_config.sh $rhsm_username $rhsm_password $roles | tee ~/repo-config.log

  ## Finally, install OSE
  echo "Installing OSE..."
  demo_password=$(random_password)
  ssh -o StrictHostKeyChecking=no root@${instance_ip} "export CONF_OPENSHIFT_PASSWORD1=$demo_password; bash " < ./openshift.conf ";
  curl -o ./openshift.sh ${SCRIPT_URL} && bash ./openshift.sh actions=do_all_actions,post_deploy | tee ~/openshift-install.log;"

  echo "Your Instance IP is: ${instance_ip}"
  echo "Done"

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
    "--ose3")
      ose3=1;;
    *) echo >&2 "Invalid option: $@"; exit 1;;
  esac
done

if [ -z $key ] || [ -z $rhsm_username ] || [ -z $rhsm_password ] || [ -z "$roles" ]; then
  echo "Missing argument."
  usage
  exit 1;
fi

if [ -z "${ose3}" ]; then
  install_ose2
else
  #install_ose3
  echo "We currently do not support install of OSE 3... coming soon."
fi
