#!/bin/bash
#lots of trouble passing around parameters especially when digging through error codes
#oo-update-application.sh {appDomain} [--appAdmins {appAdminsCSV}] [--developers {developersCSV}] [--resetAppAuthTokenID]

brokerhost="localhost"
logfile=/var/log/openshift/broker/ose-utils.log



function json {
  echo "{
        \"returnCode\":\"$1\",
        \"returnDesc\":\"$2\",
        \"authenticationTokenId\":\"$3\"
  }"

}



function usage {
  echo "Usage: oo-update-application.sh {appDomain} [--appAdmins {appAdminsCSV}] [--developers {developersCSV}] [--resetAppAuthTokenID]"
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

appDomain="$1"
reset=0
ARGS=`getopt -o h --long "appAdmins:,developers:,resetAppAuthTokenID,help" -n "oo-update-application" -- "$@"`
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
          "") json 255 "InvalidUsage"; shift;;
          *) appAdmins="$2"; shift ; shift;;
        esac
    ;;
    --developers )
        case "$2" in
          "") json 255 "InvalidUsage"; shift;;
          *) developers="$2"; shift; shift;;
        esac
    ;;

    --resetAppAuthTokenID ) reset=1; shift;;
    --help ) usage; shift; exit;;
    -- ) shift; break;;
    * ) echo "Not Recognized"; exit;;
  esac
done
echo "OUT"
#See if the Auth token is to be reset
if [ "$reset" = 1 ]; then
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+year" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
  rhc authorization-delete-all --token $TOKEN &>>$logfile
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+year" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
else
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+day" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
fi
echo "remove all"
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


#4. grant edit access on the application domain to all employeeNums listed under appAdmins
IFS=',' read -ra admins <<< $appAdmins
for employee in ${admins[*]}; do
    response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerhost/broker/rest/domains/$appDomain/members --data-urlencode role=admin --data-urlencode login=$employee 2>> $logfile | tee -a $logfile )
    status=$(exit_code "$response")
      if [ "$status" != 0 ];then
        echo "Error granting administrator permissions. Openshift API exit code $status" &>>$logfile
      fi
done

#5 Grant view access on application domain to all employees listed under developers
IFS=',' read -ra devs <<< $developers
for dev in ${devs[*]}; do
    response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerhost/broker/rest/domains/$appDomain/members --data-urlencode role=view --data-urlencode login=$dev 2>> $logfile| tee -a $logfile )
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
