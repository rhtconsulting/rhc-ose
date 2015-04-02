#!/bin/bash
#lots of trouble passing around parameters especially when digging through error codes
#oo-update-application.sh {appDomain} [--appAdmins {appAdminsCSV}] [--developers {developersCSV}] [--resetAppAuthTokenID]

logfile=/var/log/openshift/broker/ose-utils.log



function json {
  echo "{
        \"returnCode\":\"$1\",
        \"returnDesc\":\"$2\",
        \"authenticationTokenId\":\"$3\"
  }"

}



function usage {
  echo "Usage: oo-update-application.sh {appDomain} [--appAdmins {appAdminsCSV}] [--developers {developersCSV}] [--resetAppAuthTokenID] [--broker {brokerurl}]"
}

function exit_code {
  IFS=',' read -ra json <<< $1
  for section in ${json[*]}; do
      if [[ $section == *"exit_code"* ]]; then
        code=$(grep -o "[0-9]" <<< "$section")
        code=$(sed 's/ //g' <<< $code)
        status=$code
      fi
  done
}


if [ "$#" -lt 1 ]
  then
  usage
  json 255 "InvalidUsage"
  exit 255
fi

appDomain="$1"
reset=0
ARGS=`getopt -o h --long "appAdmins:,developers:,resetAppAuthTokenID,help,broker:" -n "oo-update-application" -- "$@"`
if [ "$?" != 0 ];then
  json 255 "Invalid Usage"
  usage;
  exit
fi
shift;
eval set -- "$ARGS";
while true; do
  case "$1" in
    --appAdmins )
        case "$2" in
          "") json 255 "InvalidUsage"; usage; shift;;
          *) appAdmins="$2"; shift ; shift;;
        esac
    ;;
    --developers )
        case "$2" in
          "") json 255 "InvalidUsage"; usage; shift;;
          *) developers="$2"; shift; shift;;
        esac
    ;;
    --broker )
        case "$2" in
          "") json 255 "Invalid Usage"; usage; shift;;
          *) brokerHost="$2"; shift;shift;;
        esac
    ;;
    --resetAppAuthTokenID ) reset=1; shift;;
    --help ) usage; shift; exit;;
    -- ) shift; break;;
    * ) echo "Not Recognized"; exit;;
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

#See if the Auth token is to be reset
if [ "$reset" = 1 ]; then
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+year" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
  rhc authorization-delete-all --token $TOKEN &>>$logfile
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+year" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
else
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+day" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
fi
#remove all admins and developers
rhc member-remove -n $appDomain --all --token $TOKEN &>>$logfile
status="$?"
if [ "$status" != 0 ];then

    if [ reset = 1 ];then
      json 255 "Error changing member status. Check to make sure you have valid permissions. rhc exit code: $status" $TOKEN
    else
      json 255 "Error changing member status. Check to make sure you have valid permissions. rhc exit code: $status"
    fi
    exit 255
fi


IFS=',' read -ra admins <<< $appAdmins
for user in ${admins[*]}; do
    response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerHost/broker/rest/domains/$appDomain/members --data-urlencode role=admin --data-urlencode login=$user 2>> $logfile | tee -a $logfile )
    status=$(exit_code "$response")
      if [ "$status" != 0 ];then
        echo "Error granting administrator permissions. Openshift API exit code $status" &>>$logfile
      fi
done

IFS=',' read -ra devs <<< $developers
for dev in ${devs[*]}; do
    response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerHost/broker/rest/domains/$appDomain/members --data-urlencode role=view --data-urlencode login=$dev 2>> $logfile| tee -a $logfile )
    status=$(exit_code "$response")
    if [ "$status" != 0 ];then
        echo "Error granting developer permissions. Openshift API exit code $status" &>>$logfile
    fi
done
if [ "$reset" = 1 ]; then
  json 0 "Success" $TOKEN
else
  #remove temporary token
  rhc authorization-delete $TOKEN --token $TOKEN &>>$logfile
  json 0 "Success"
fi

exit 0
