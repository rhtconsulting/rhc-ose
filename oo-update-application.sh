#!/bin/bash
#lots of trouble passing around parameters especially when digging through error codes

#oo-update-application.sh {appDomain} [--appAdmins {appAdminsCSV}] [--developers {developersCSV}] [--resetAppAuthTokenID]
brokerhost="localhost"

function json {
  echo "{
        'returnCode':'$1',
        'returnDesc':'$2',
        'authenticationTokenId':'$3'

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
        export status=$code

      fi
  done
}

if [ "$#" -lt 1 ]
  then
  json 255 "Invalid Usage"
  usage
  exit 255
fi
appDomain="$1"
if [ -z ${appDomain+x} ]
  then
  json 255 "Invalid Usage"
  usage
  exit 255
fi

if [ "$2" != "--appAdmins" ] && [ "$2" != "--developers" ]
  then
  json 255 "Unrecognized Flag"
  usage
  exit 255
fi

if [ "$2" = "--appAdmins" ]
  then
  appAdminCVS=$3
elif [ "$2" = "--developers" ]
  then
  developers=$3
fi

if [ "$4" = "--appAdmins" ]
  then
  appAdminCVS=$5
elif [ "$4" = "--developers" ]
  then
  developers=$5
fi

#See if the Auth token is to be reset
for arg in $*; do
  if [ "$arg" = "--resetAppAuthTokenID" ]; then
  respose=$(curl -k -H "Authorization: Bearer $TOKEN" -X GET https://$brokerhost/broker/rest/user/authorizations/ --data-urlencode role=admin --data-urlencode login=$employee)
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+year" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
  fi
done

if [ -z ${TOKEN+x} ];then
  TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+day" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"
fi

#4. grant edit access on the application domain to all employeeNums listed under appAdmins
IFS=',' read -ra admins <<< $appAdminCVS
echo ""
for employee in ${admins[*]}; do
    response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerhost/broker/rest/domains/$appDomain/members --data-urlencode role=admin --data-urlencode login=$employee)
    exit_code $response
    echo "$response"
    if [ "$status" != "0" ];then
        json 255 "Openshift API exit code $status"

        exit 255
    fi
    echo "ADMIN registered"

done

#5 Grant view access on application domain to all employees listed under developers

IFS=',' read -ra devs <<< $developers

for dev in ${devs[*]}; do
    export response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerhost/broker/rest/domains/$appDomain/members --data-urlencode role=view --data-urlencode login=$dev)
    exit_code $response
    echo "$response"
    if [ "$status" != 0 ];then
        json 255 "Openshift API exit code $status"
        exit 255
    fi
    echo "developer registered"
done

json 0 "Success" $TOKEN
exit 0
