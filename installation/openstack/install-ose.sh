#!/bin/bash
SCRIPT_URL=https://github.com/openshift/openshift-extras/raw/enterprise-2.2/enterprise/install-scripts/generic/openshift.sh
instance_ip=$1; shift;

usage() {
  echo "Usage: $0 [instance_ip] [rhsm-username] [rhsm-password] [roles]"
  echo "  Currently Supported Roles:
    - broker
    - node"
}

if [ $# -lt 3 ]; then
  echo "Invalid number of arguments."
  usage
  exit 1
fi

## Run Broker and Node setup scripts
ssh -o StrictHostKeyChecking=no root@${instance_ip} "bash -s" -- < ../repo_config.sh $@

ssh -o StrictHostKeyChecking=no root@${instance_ip} "curl -o ${SCRIPT_URL} && ./openshift.sh"
