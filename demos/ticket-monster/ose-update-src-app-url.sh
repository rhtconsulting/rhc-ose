#!/bin/bash



usage() {
  echo "Usage $0 -h|--host=\"<host>\" -u|--user=\"<username>\" -p|--password=\"<password>\" -n|--namespace=\"<namespace>\" -a|--app=\"<app>\" -s|--source=\"<source>\""
}



# Process Input

for i in "$@"
do
  case $i in
    -h=*|--host=*)
      HOST="${i#*=}"
      shift;;
    -u=*|--user=*)
      USER="${i#*=}"
      shift;;
    -p=*|--password=*)
      PASSWORD="${i#*=}"
      shift;;
    -n=*|--namespace=*)
      NAMESPACE="${i#*=}"
      shift;;
    -a=*|--app=*)
      APP="${i#*=}"
      shift;;
    -s=*|--source=*)
      SOURCE="${i#*=}"
      shift;;
  esac
done

if [ -z $HOST ] || [ -z $USER ] || [ -z $PASSWORD ] || [ -z $NAMESPACE ] || [ -z $APP ] || [ -z $SOURCE ]; then
  echo "Missing required arguments!"
  usage
  exit 1
fi 


# Get auth token
CHALLENGE_RESPONSE=$(curl -s  -I --insecure -f  "https://${HOST}:8443/oauth/authorize?response_type=token&client_id=openshift-challenging-client" --user ${USER}:${PASSWORD} -H "X-CSRF-Token: 1")

if [ $? -ne 0 ]; then
    echo "Error: Unauthorized Access Attempt"
    exit 1
fi

TOKEN=$(echo "$CHALLENGE_RESPONSE" | grep -oP "access_token=\K[^&]*")

if [ -z "$TOKEN" ]; then
    echo "Token is blank!"
    exit 1
fi

# Get build config for app
BUILD_CONFIG=$(curl -s -H "Authorization: Bearer ${TOKEN}" --insecure -f https://${HOST}:8443/osapi/v1beta3/namespaces/${NAMESPACE}/buildconfigs/${APP})

if [ -z "$BUILD_CONFIG" ]; then
    echo "Error locating build config"
    exit 1
fi

# Cleanse Source for sed
CLEANSED_SOURCE=$(echo $SOURCE | sed 's/[_&$]/\\&/g')

# Update version of artifact
UPDATED_BUILD_CONFIG=$(echo "$BUILD_CONFIG" | sed "s|\"value\": \"http.*|\"value\": \"$CLEANSED_SOURCE\"|")

# Update buildconfig in OSE
curl -s -X PUT -d "${UPDATED_BUILD_CONFIG}" -H "Authorization: Bearer ${TOKEN}" --insecure -f https://${HOST}:8443/osapi/v1beta3/namespaces/${NAMESPACE}/buildconfigs/${APP} > /dev/null

if [  $? -ne 0  ]; then
    echo "Error updating build configuration"
    exit 1
fi

echo
echo "Application source has been updated!"
