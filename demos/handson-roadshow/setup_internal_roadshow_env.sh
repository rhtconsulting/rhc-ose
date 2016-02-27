#!/bin/bash

set -e

# Global variables
NUM_USERS=30
USER_PREFIX=
USER_BASE=user
PASSWORD=redhat
OSE_GROUP=roadshow-users
OSE_ROLE=view
OSE_PROJECT=ose-roadshow-demo
OSE_DOMAIN=ose.example.com
OSE_APP_SUBDOMAIN=apps

PASSWD_FILE=/etc/origin/openshift-passwd

# Show script usage
usage() {
  echo "
  Usage: $0 [options]

  Options:
  --user-base=<user base>          : Base user name (Default: user)
  --user-prefix=<user prefix>      : User prefix
  --num-users=<num users>          : Number of Users to provision (Default: 30)
  --group=<group>                  : Name of the group to create (Default: roadshow-users)
  --role=<role>                    : Name of the role to give to the newly created group for the demo project (Default: view)
  --project=<project>              : Name of the demo project to create (Default: ose-roadshow-demo)
  --domain=<domain>                : Domain name for smoke test route (Default: ose.example.com)
  --app-subdomain=<app subdomain>  : Subdomain name for smoke test route (Default: apps)
  --passwd-file=<passwd file>      : OpenShift htpasswd file (Default: /etc/origin/openshift-passwd)
   "
}



# Process input
for i in "$@"
do
  case $i in
    --user-base=*)
      USER_BASE="${i#*=}"
      shift;;
    --user-prefix=*)
      USER_PREFIX="${i#*=}"
      shift;;
    --num-users=*)
      NUM_USERS="${i#*=}"
      shift;;
    --group=*)
      OSE_GROUP="${i#*=}"
      shift;;
    --role=*)
      OSE_ROLE="${i#*=}"
      shift;;
    --project=*)  
      OSE_PROJECT="${i#*=}"
      shift;;
    --domain=*)  
      OSE_DOMAIN="${i#*=}"
      shift;;
    --app-subdomain=*)  
      OSE_APP_SUBDOMAIN="${i#*=}"
      shift;;
    --passwd-file=*)  
      PASSWD_FILE="${i#*=}"
      shift;;
     *)
      echo "Invalid Option: ${i#*=}"
      exit 1;
      ;;
  esac
done

users=

for i in $(seq -f "%02g" 0 $NUM_USERS)
do
	
	username=${USER_PREFIX}${USER_BASE}${i}
  
	# Create new Users
	htpasswd -b ${PASSWD_FILE} $username ${PASSWORD}
	
	# Create Comma Separated List for Groups
	users+="\"${username}\","
	
done


# Hold current project name to switch back into
current_project=$(oc project --short)


echo
echo "Running Logging Configuration..."
echo
oadm new-project logging
oc project logging

oadm ca create-server-cert --signer-cert=/etc/origin/master/ca.crt  \
                            --signer-serial=/etc/origin/master/ca.serial.txt \
                            --signer-key=/etc/origin/master/ca.key \
                            --hostnames="*.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN}" \
                            --cert=/etc/origin/master/kibana.crt --key=/etc/origin/master/kibana.key

oc secrets new logging-deployer \
     kibana.crt=/etc/origin/master/kibana.crt kibana.key=/etc/origin/master/kibana.key

echo 'apiVersion: v1
kind: ServiceAccount
metadata:
  name: logging-deployer
secrets:
- name: logging-deployer' | oc create -f -


oc policy add-role-to-user edit system:serviceaccount:logging:logging-deployer

oadm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-fluentd
oadm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-elasticsearch

oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:logging:aggregated-logging-fluentd

oc process logging-deployer-template -n openshift \
  -v KIBANA_HOSTNAME=kibana.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN},ES_CLUSTER_SIZE=1,PUBLIC_MASTER_URL=https://master.${OSE_DOMAIN}:8443,ENABLE_OPS_CLUSTER=true,KIBANA_OPS_HOSTNAME=kibana-ops.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN} > logging-deployer.json

oc create -f logging-deployer.json

rm -f logging-deployer.json

set +e

export sleep_time=3;
export deployer_completed=0;
while [ $deployer_completed == 0 ] ; do
echo "---Checking if deployer has completed"
sleep $sleep_time;

oc get pods | grep logging-deployer | grep -i Completed

if [ $? == 0 ]
then
	echo "----Deployer has completed" ; export deployer_completed=1;
else
 	echo "----Deployer has NOT completed" ;
fi

done

oc logs `oc get pods | grep logging-deployer | grep -i Completed | awk '{print $1}'`

#Deploy a template that is created by the deployer:
oc process logging-support-template | oc create -f -

#To view all current deployments used by Elasticsearch:
oc get dc --selector logging-infra=elasticsearch



export running_pods=`oc get pods | grep -vi deploy | grep -c Running`
export expected_pods=4;
while [ $running_pods -lt $expected_pods ] ; do
echo "---Checking if non-deployment pods are running - expected $expected_pods"
sleep $sleep_time;

export running_pods=`oc get pods | grep -vi deploy | grep -c Running`

if [ running_pods == 4 ]
then
	echo "----$running_pods non-deployment pods are running"
else
 	echo "----$running_pods non-deployment pods are running"
fi

done

set -e

# Scale the "logging-fluentd" deployment to the amount of nodes you have:

export RunningNodes=`oc get nodes | grep -v SchedulingDisabled | grep -c Ready`
oc scale dc/logging-fluentd --replicas=${RunningNodes}

#Edit the `/etc/origin/master/master-config.yaml` file to allow access to the Kibana service:
sed -i  "/publicURL:/ a \ \ loggingPublicURL: \"https://kibana.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN}\"" /etc/origin/master/master-config.yaml
systemctl restart atomic-openshift-master ; systemctl status  atomic-openshift-master

echo
echo "Running Metrics Configuration..."
echo

oc project openshift-infra

oc create -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-deployer
secrets:
- name: metrics-deployer
EOF

oadm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster

oadm ca create-server-cert --key=/etc/origin/master/hawkular-metrics.key --cert=/etc/origin/master/hawkular-metrics.crt --hostnames=hawkular-metrics,hawkular-metrics.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN} --signer-cert=/etc/origin/master/ca.crt --signer-key=/etc/origin/master/ca.key --signer-serial=/etc/origin/master/ca.serial.txt
cat /etc/origin/master/hawkular-metrics.key /etc/origin/master/hawkular-metrics.crt > /etc/origin/master/hawkular-metrics.pem

oc secrets new metrics-deployer hawkular-metrics.pem=/etc/origin/master/hawkular-metrics.pem hawkular-metrics-ca.cert=/etc/origin/master/ca.crt


cp /usr/share/ansible/openshift-ansible/roles/openshift_examples/files/examples/v1.1/infrastructure-templates/enterprise/metrics-deployer.yaml $(pwd)/metrics.yaml
set +e

#POD=$(oc process -f metrics.yaml -v HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN},USE_PERSISTENT_STORAGE=false,IMAGE_PREFIX=openshift3/,IMAGE_VERSION=latest  | oc create -f - | cut -d '"' -f2)
POD=$(oc process -f metrics.yaml -v HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN},USE_PERSISTENT_STORAGE=false | oc create -f - | cut -d '"' -f2)
while [ "$(oc get pod $POD -o template --template='{{.status.phase}}')" != "Succeeded" ]; do
  sleep 1
done

set -e

oc get rc -o yaml | sed -e 's/imagePullPolicy: .*/imagePullPolicy: IfNotPresent/' | oc replace -f -
oc delete pods --all

sed -i  "/publicURL:/ a \ \ metricsPublicURL: \"https://hawkular-metrics.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN}/hawkular/metrics\"" /etc/origin/master/master-config.yaml
service atomic-openshift-master restart




oc project default &>/dev/null

echo "{ \"kind\": \"Group\", \"apiVersion\": \"v1\", \"metadata\": { \"name\": \"${OSE_GROUP}\", \"creationTimestamp\": null }, \"users\": [ ${users%?} ] }" | oc create -f -

oc new-project ${OSE_PROJECT} --display-name="OpenShift Roadshow Demo" --description="OpenShift Roadshow Demo Project"

oadm policy add-role-to-group ${OSE_ROLE} ${OSE_GROUP}  -n ${OSE_PROJECT}

oc new-app https://github.com/gshipley/smoke -n ${OSE_PROJECT}

oc scale dc smoke --replicas=2 -n ${OSE_PROJECT} &>/dev/null

oc expose service smoke --hostname=smoketest.${OSE_APP_SUBDOMAIN}.${OSE_DOMAIN} &>/dev/null


oc project $current_project &>/dev/null


