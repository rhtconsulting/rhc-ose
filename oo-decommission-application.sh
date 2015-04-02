#!/bin/bash
#***IMPORTANT***
# please ensure that oo-delete-user is found in path or /root


logfile=/var/log/openshift/broker/ose-utils.log
function usage {
  echo "Usage: oo-decommission-application-simulator.sh {appDomain} {Token} [--broker {brokerUrl}]"
}

function json {
  echo "{
        \"returnCode\":\"$1\",
        \"returnDesc\":\"$2\",
  }"

}

function exit_code {
  IFS=',' read -ra json <<< "$1"
  for section in ${json[*]}; do
      if [[ $section == *"exit_code"* ]]; then
        code=$(grep -o "[0-9]" <<< "$section")
        code=$(sed 's/ //g' <<< "$code")
        code=$(echo $code | tr -d '\n')
        echo "code====$code" &>> $logfile
        echo "$code"
      fi
  done

}
if [ ! -f /usr/local/bin/oo-delete-user ]; then
  json 255 "oo-delete-user could not be found at /usr/local/bin/"
  exit 255
fi

if [ "$#" -lt 2 ]
  then
  usage
  json 255 "Invalid usage"
  exit 255
fi

appDomain="$1"
TOKEN="$2"
ARGS=`getopt -o h --long "broker:" -n "oo-decommission-application" -- "$@"`
shift;
eval set -- "$ARGS";
while true; do
  case "$1" in
    --broker )
        case "$2" in
          "") json 255 "InvalidUsage"; shift;;
          *) brokerHost="$2"; shift ; shift;;
        esac
    ;;
    --) shift; break;;
  esac
done

if [ -z "$brokerHost" ]; then
  broker=$(grep "^ServerName" /etc/httpd/conf.d/000002_openshift_origin_broker_servername.conf)
  IFS=' '; read -r -a broker <<< "$broker"
  brokerHost="${broker[1]}"
  if [ -z "$brokerHost" ]; then
    json 255 "brokerHost not set"
    exit 255
  fi
fi

if [[ $appDomain -gt 16 ]];then #appdomain is longer than 16 error out
   json 255 "App Domain too long"
   exit 255
fi

if [[ "$appDomain" != [0-9A-Za-z]* ]];then #appdomain is longer than 16 error out
   json 255 "Illegal characters for application domain"
   exit 255
fi
#loop through domains here TODO
response=$(curl -k -H "Authorization: Bearer $TOKEN" -X DELETE https://$brokerHost/broker/rest/domains/$appDomain --data-urlencode force=true 2>> $logfile | tee -a $logfile )
status=$(exit_code "$response")

if [ "$status" != 0 ] && [ "$status" != 127 ];then
  echo "Error deleting domain. Openshift API exit code $status" &>>$logfile
  json 255 "Error deleting domain. Openshift API exit code $status"
  exit 255

else

  /usr/local/bin/oo-delete-user "$appDomain" "$TOKEN" "$brokerHost" &>>$logfile
  status="$?"
  if [ "$status" != 0 ] ; then
    json 255 "Error deleting user. Openshift exit code: $status"
    exit 255
  fi
fi
  response=$(curl -k -H "Authorization: Bearer $TOKEN" -X DELETE https://$brokerHost/broker/rest/user/authorizations/$appDomain --data-urlencode force=true 2>> $logfile | tee -a $logfile )
  status=$(exit_code "$response")

  if [ "$status" != 0 ] ; then
    json 255 "Error deleting user. Openshift exit code: $status"
    exit 255
  else
    json 0 "Success"
    exit 0
  fi

fi
