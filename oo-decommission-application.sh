brokerHost="broker.e1.epaas.aexp.com"
platformDomain="e1.epaas.aexp.com"

function usage {
  echo "Usage: oo-decommission-application-simulator.sh {appDomain} {Token}"
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
        code=$(sed 's/ //g' <<< $code)
        echo "$code"
      fi
  done
}

if [ "$#" -lt 2 ]
  then
  usage
  json 255 "Invalid usage"
  exit 255
fi

appDomain="$1"
TOKEN="$2"


if [[ $appDomain -gt 16 ]];then #appdomain is longer than 16 error out
   json 255 "App Domain too long"
   exit 255
fi

if [[ "$appDomain" != [0-9A-Za-z]* ]];then #appdomain is longer than 16 error out
   json 255 "Illegal characters for application domain"
   exit 255
fi

response=$(curl -k -H "Authorization: Bearer $TOKEN" -X DELETE https://$brokerhost/broker/rest/domains/$appDomain --force --user $appDomain  2>> $logfile | tee -a $logfile )
status=$(exit_code "$response")

if [ "$status" != 0 ];then
  echo "Error deleting domain. Openshift API exit code $status" &>>$logfile
  json 255 "Error deleting domain"
  exit 255

else
  json 0 "Success"
  exit 0
fi
