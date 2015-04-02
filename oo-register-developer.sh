#! /bin/bash
#oo-register-developer <username> [gearProfile]


logFile=/var/log/openshift/broker/ose-utils.log

gearProfileDefault="small"
maxDevGears="3"

function usage {
  echo "oo-register-developer.sh {username} [gearProfile]"
}

function json {
  echo "{
        \"returnCode\":\"$1\",
        \"returnDesc\":\"$2\"
}"
}

function validGear {
  valid=$(grep "VALID_GEAR_SIZES=" /etc/openshift/broker.conf | tee -a $logFile )
  valid=$(sed 's/"//g' <<< $valid)

  IFS='='; read -r -a raw <<< "$valid"
  IFS=','; read -r -a sizes <<< "${raw[1]}"

  for size in ${sizes[*]}
  do

    if [[ $size = $1 ]]; then
      echo 1
      return
    fi
  done
  echo 0
  return

}

if [ "$#" -lt 1 ];then
  usage
  json 255 "Invalid usage"
  exit 255
fi

username="$1"
gearProfile="$2"

if [ -z $2 ];then
  gearProfile="$gearProfileDefault"
else
  checkGear=$(validGear "$gearProfile")
  if [ $checkGear -ne 1 ];then
    json 255 "Invalid Gear Size."
    exit 255
  fi
fi

if [ -z ${username+x} ];then
  usage
  json 2 "No Username supplied"
  exit 255
fi

#check if user exists and catch output(should produce a not found error since the user shouldnt exist)
oo-admin-ctl-user -l $username &>>$logFile
code=$?
if [[ "$code" = "5" ]]; then

  #Do nothing here but bash doesnt like empty if statement go on to create new account.
  sleep 0

elif [[ "$code" = "0" ]]; then
  #already exists do nothing return 1

  json 1 "User already exists. Exiting..."
  exit 1
else
  #Unknow error
  echo "error=$code"
  json 255 "Unknown Error. Exiting..."
  exit 255;
fi

oo-admin-ctl-user --create -l $username &>>$logFile
TOKEN="$(oo-auth-token -l $username -e "$(date -d "+day")" 2>>$logFile| tee -a $logFile)"

# set max gears for developer accounts
oo-admin-ctl-user -l $username --setmaxgears $maxDevGears &>>$logFile


curl -H "Authorization: Bearer $TOKEN" -k -X POST https://$brokerHost/broker/rest/domains/ --data-urlencode name=dev$username --data-urlencode allowed_gear_sizes=$gearProfile &>>"$logFile"

json 0 "Succcess"
exit 0
