#!/bin/bash

#
#   Copyright 2016 Red Hat Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

#
# certificates-secrets-metrics-logging.sh - Script to automate the creation of certificates and a secret for the Metrics and Logging Deployers
#
# Usage: See usage function below
#

set -e

OSE_MASTER_ETC_HOME="/etc/origin/master"

usage() {
  echo "
  Usage: $0 [options]

  Options:
  -h|--hostname=<hostname>                  : Hostname(s) for pass into the certificate generation
  -t|--type=<logging|metrics>               : Type of operation to perform (Logging or Metrics)
  -p|--project=<project>                    : Overrides the default project name for the type"
}


# Process input
for i in "$@"
do
  case $i in
    -h=*|--hostname=*)
      HOSTNAME="${i#*=}"
      shift;;
    -t=*|--type=*)
      TYPE="${i#*=}"
      shift;;
    -p=*|--project=*)
      PROJECT="${i#*=}"
      shift;;
      *)
      echo "Invalid Option: ${i#*=}"
      usage
      exit 1;
      ;;
  esac
done


function do_logging() {
    
    LOGGING_PROJECT=${PROJECT:-logging}
    
    oadm ca create-server-cert --key=$OSE_MASTER_ETC_HOME/kibana.key --cert=$OSE_MASTER_ETC_HOME/kibana.crt --hostnames=kibana,$HOSTNAME --signer-cert=$OSE_MASTER_ETC_HOME/ca.crt --signer-key=$OSE_MASTER_ETC_HOME/ca.key --signer-serial=$OSE_MASTER_ETC_HOME/ca.serial.txt
    
    oc secrets new logging-deployer kibana.crt=$OSE_MASTER_ETC_HOME/kibana.crt kibana.key=$OSE_MASTER_ETC_HOME/kibana.key kibana-ops.crt=$OSE_MASTER_ETC_HOME/kibana.crt kibana-ops.key=$OSE_MASTER_ETC_HOME/kibana.key ca.crt=$OSE_MASTER_ETC_HOME/ca.crt ca.key=$OSE_MASTER_ETC_HOME/ca.key -n $LOGGING_PROJECT

}

function do_metrics() {
    
    METRICS_PROJECT=${PROJECT:-openshift-infra}
    
    oadm ca create-server-cert --key=$OSE_MASTER_ETC_HOME/hawkular-metrics.key --cert=$OSE_MASTER_ETC_HOME/hawkular-metrics.crt --hostnames=hawkular-metrics,$HOSTNAME --signer-cert=$OSE_MASTER_ETC_HOME/ca.crt --signer-key=$OSE_MASTER_ETC_HOME/ca.key --signer-serial=$OSE_MASTER_ETC_HOME/ca.serial.txt
    cat $OSE_MASTER_ETC_HOME/hawkular-metrics.key $OSE_MASTER_ETC_HOME/hawkular-metrics.crt > $OSE_MASTER_ETC_HOME/hawkular-metrics.pem

    oc secrets new metrics-deployer hawkular-metrics.pem=$OSE_MASTER_ETC_HOME/hawkular-metrics.pem hawkular-metrics-ca.cert=$OSE_MASTER_ETC_HOME/ca.crt -n $METRICS_PROJECT

}


# Validation Checks
if [ -z "$HOSTNAME" ]; then
    echo "Error: Metrics Hostname must be provided"
    exit 1
fi


if [ ! -d /etc/origin/master ]; then
    echo "Error: Unable to locate OpenShift Master Directory"
    exit 1
fi

if [ "$TYPE" != "logging" ] && [ "$TYPE" != "metrics" ]; then
    echo "Error: Invalid Type Specifed. Must enter 'logging' or 'metrics'"
    exit 1
fi

# Execute function
echo "About to execute function $TYPE"
do_$TYPE

