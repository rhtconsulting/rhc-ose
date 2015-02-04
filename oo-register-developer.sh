#! /bin/bash
#oo-register-developer <username> <gearProfile>
#
#SETUP
# simple set the broker host variable below to the correct url for the broker and [OPTIONAL] set the logfile where to send stdout & stderr
#
#PARAMETERS
#username: username of the developer to add. script will create developer with name "dev[username]"
#gearProfile: gear profile to be used in the developers domain eg. small, medium
#
#
#VARIABLES
#logFile: where the stderr and stdout get redirected to
#brokerhost: url of the OSE broker
#
#
#EXAMPLES
# ./oo-register-developer.sh Jsmith small
# ./oo-register-developer.sh Bnye medium
#
#
logFile=/var/log/openshift/broker/ose-utils.log
brokerhost="localhost"
gearProfileDefault="small"

function usage {
  echo "oo-register-developer.sh {username} {gearProfile}"
}

function json {
  echo "{
        'returnCode':'$1',
        'returnDesc':'$2'
}"
}

function validGear {
  valid=$(grep "VALID_GEAR_SIZES=" /etc/openshift/broker.conf | tee -a $logFile )
  valid=$(sed 's/"//g' <<< $valid)

  IFS='='; read -r -a raw <<< "$valid"
  IFS=','; read -r -a sizes <<< "${raw[1]}"

  for size in ${sizes[*]}
  do

    if [[ $size == $1 ]]; then
      echo 1
      return
    fi
    echo "$size did not equal $1"
  done
  echo 0
  return

}

if [ "$#" -lt 1 ]
  then
  usage
  json 255 "Invalid usage"
  exit 255
fi

username="$1"
gearProfile="$2"

if [ -z ${gearProfile+x} ];then
  $gearProfile=$gearProfileDefault
else
  checkGear=$(validGear "$gearProfile")
  if [ "$checkGear" != "1" ];then
    json 255 "Invalid Gear Size."
    exit 255
  fi
fi

if [ -z ${username+x} ];then
  usage
  json 2 "No Username supplied"
  exit 255
fi





#1. Check if developer account already exists in OpenShift E1
#   (API TBD, Java RA and Red Hat working on this one). If it does not, then:

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
  echo "error=$?"
  json 255 "Unknown Error. Exiting..."
  exit 255;
fi

#   a.  Create  developer account in OpenShift E1   HSC to OpenShift API TBD,Java RA and Red Hat working on this one
oo-admin-ctl-user --create -l $username &>>$logFile

TOKEN="$(oo-auth-token -l $username -e "$(date -d "+year")" 2>>$logFile| tee $logFile)"


#   b.  Create developer domain in OpenShift E1 (a.k.a. remote E0 in ePaaS)       HSC to OpenShift API, POST /broker/rest/domains
#       (e.g. “curl -k -X POST https://LPDCLDWA00608.phx.aexp.com/broker/rest/domains --user cdSystemAccount:password name=username allowed_gear_sizes=standard”,
#       note the actual hostname and gear sizes will be different and will be defined once we get the VMs)


curl -H "Authorization: Bearer $TOKEN" -k -X POST https://$brokerhost/broker/rest/domains/ --data-urlencode name=dev$username --data-urlencode allowed_gear_sizes=$gearProfile &>>"$logFile"

json 0 "Succcess"
exit 0
