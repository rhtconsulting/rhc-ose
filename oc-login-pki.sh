#!/bin/bash

# oc-login-pki.sh
# Taylor Biggs

# a simple "oc login" wrapper that uses a RequestHeader "Challenging Proxy" setup with x509/PKI certificates (passwordless) for authentication
# (https://docs.openshift.com/enterprise/3.1/install_config/configuring_authentication.html#RequestHeaderIdentityProvider)

# usage
# oc-login-pki.sh <user certificate file> <user key file> <server FQDN>

usage() {
  echo "Usage: $0 <user certificate file> <user key file> <server FQDN>"
  exit 1
}

if [[ $3 == '' ]]
then
  echo "Expecting three arguments"
  usage
fi

if [[ $4 != '' ]]
then
  echo "Expecting three arguments"
  usage
fi

if [[ ! -r $1 ]]
then
  echo "$1 is not a readable file"
  usage
fi

if [[ ! -r $2 ]]
then
  echo "$2 is not a readable file"
  usage
fi

CERT=$(realpath $1)
KEY=$(realpath $2)
SERVER=$3

OC_TOKEN=$(curl --cert ${CERT} --key ${KEY} -k -v -XGET -H "X-Csrf-Token: 1" "https://${SERVER}/challenging-proxy/oauth/authorize?response_type=token&client_id=openshift-challenging-client" 2>&1 | grep Location | awk -F\# '{print $2}' | sed s/access_token=// | awk -F\& '{print $1}')
oc --token=$OC_TOKEN --server=${3}:8443 login
