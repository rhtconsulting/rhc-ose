#!/bin/bash
#oo-register-application.sh {gearProfile}{appDomain} [--appAdmins {appAdminsCSV}] [--developers {developersCSV}]
#SETUP
# Set the broker host variable below to the correct url for the broker and [OPTIONAL] set the logfile where to send stdout & stderr
# Set the appDomain to the user who will own authenticate to register the application "appDomain" in the Onboard flows document
#
#PARAMETERS
#
#[REQUIRED]gearProfile: gear profile to be used in the application eg. small, medium
#[REQUIRED]appDomain: the domain of the application eg. applicationX
#[OPTIONAL]--appAdmins <comma-separtated list> of users to be granted admin access
#[OPTIONAL]--developers <comma-separtated list> of users to be granted developer access
#IMPORTANT NOTE: Comma-separated lists may not contain spaces.
#
#
#VARIABLES
#logFile: where the stderr and stdout get redirected to
#brokerHost: url of the OSE broker
#
#
#EXAMPLES
# ./oo-register-application.sh small app1 --appAdmins kyle1 --developers ryanT,lucy34
# ./oo-register-application.sh small applicationx --appAdmins kyle1,rebecca4
#
#

#brokerHost="localhost"
#defaultGearProfile="small"
logfile=/var/log/openshift/broker/ose-utils.log

brokerHost="broker.e1.epaas.aexp.com"
platformDomain="e1.epaas.aexp.com"

#GLOBAL VARIABLES
force=0

function usage {
  echo "Usage: oo-register-application.sh {gearProfile} {appDomain} [--appAdmins {appAdminsCSV}] [--developers {developersCSV}]"
}

function json {
  echo "{
        \"returnCode\":\"$1\",
        \"returnDesc\":\"$2\",
        \"authenticationTokenId\":\"$3\",
        \"appDomainFullyQualified\":\"$4\"
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

function validGear {
  valid=$(grep "VALID_GEAR_SIZES=" /etc/openshift/broker.conf | tee -a $logfile )
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
function getGearDefault {
  valid=$(grep "DEFAULT_GEAR_CAPABILITIES=" /etc/openshift/broker.conf | tee -a $logfile )
  valid=$(sed 's/"//g' <<< $valid)

  IFS='='; read -r -a default <<< "$valid"
  IFS=','; read -r -a size <<< "${default[1]}"

  echo "$size"
  return
}



if [ "$#" -lt 1 ]
  then
  usage
  json 255 "InvalidUsage"
  exit 255
fi


gearProfile="$1"
appDomain="$2"
ARGS=`getopt -o h --long "appAdmins:,developers:,force" -n "oo-register-application" -- "$@"`
shift;shift;
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
    --force )
        shift;
        force=1;
    ;;
    -h ) usage;;
    --) shift; break;;
    *) echo "not recognized";;

  esac
done
#check that devs and admin strings dont contain illegal characters or are empty
if [[ -n "$appAdmins" && "$appAdmins" != [0-9A-Za-z,]* || -n "$developers" && "$developers" != [0-9A-Za-z,]* ]];then
   json 255 "UnknownError. Invalid Username detected"
   exit 255
fi


if [[ ${#appDomain} -gt 16 ]];then #appdomain is longer than 16 error out
   json 255 "UnknownError. App Domain too long"
   exit 255
fi

if [[ "$appDomain" != [0-9A-Za-z]* ]];then #appdomain is longer than 16 error out
   json 255 "UnknownError. Illegal characters for application domain"
   exit 255
fi

# #1. Create internal Openshift user "$appDomain"
# result=$(oo-admin-ctl-user -c -l $appDomain 2>>$logfile | tee -a $logfile)
# if [ "$result" = "0" ]; then
#   json 1 "The user $appDomain already exists!" "" ""
#   exit 1
# fi
oo-admin-ctl-user -l $appDomain &>>$logfile
code=$?
if [[ "$code" = "5" ]]; then
   #appDomain is free lets create user appDomain
   oo-admin-ctl-user -c -l $appDomain &>>$logfile

elif [[ "$code" = "0" ]]; then
  #already exists do nothing return 1
  if [ $force -ne 1 ]; then
    json 1 "AlreadyExists"
    exit 1
  fi
  echo "User already exists. Continuing on behalf of --force" &>>$logfile
else
  #Unknow error
  echo "error=$code"
  json 255 "UnknownError"
  exit 255;
fi

#Create Token (expires a year from creation
TOKEN="$(oo-auth-token -l $appDomain -e "$(date -d "+year" 2>> $logfile | tee -a $logfile)" 2>> $logfile | tee -a $logfile)"

gearDefault=$(getGearDefault)

#echo "default:$gearDefault gearProfile:$gearProfile brokerHost:$brokerHost appDomain:$appDomain"

if [ "$gearDefault" = "e1dev-standard" ];then
    oo-admin-ctl-user -l $appDomain --addgearsize $gearProfile --removegearsize $gearDefault &>>$logfile
fi
#2. Create application domain owned by appDomain Openshift user $appDomain
response=$(curl -k -H "Authorization: Bearer $TOKEN" -X POST https://$brokerHost/broker/rest/domains/ --data-urlencode name=$appDomain 2>> $logfile | tee -a $logfile 2>> $logfile)
status=$(exit_code "$response")
if [ "$status" = 103 ] && [ "$force" != 1 ];then
    json 1 "AlreadyExists. Openshift API exit code $status" $TOKEN
    exit 1

elif [ "$status" = 103 ] && [ "$force" = 1 ];then
    echo "Forcing changed to existing domain" &>> $logfile

elif [ "$status" != 0 ];then
     json 255 "UnknownError. Error creating domain. Openshift API exit code $status" $TOKEN
     exit 255
fi


#4. grant edit access on the application domain to all employeeNums listed under appAdmins
IFS=',' read -ra admins <<< $appAdmins
for employee in ${admins[*]}; do
    response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerHost/broker/rest/domains/$appDomain/members --data-urlencode role=admin --data-urlencode login=$employee 2>> $logfile | tee -a $logfile )
    status=$(exit_code "$response")
      if [ "$status" != 0 ];then
        echo "Error granting administrator permissions. Openshift API exit code $status" &>>$logfile
      fi
done

#5 Grant view access on application domain to all employees listed under developers

IFS=',' read -ra devs <<< $developers

for dev in ${devs[*]}; do
    response=$(curl -k -H "Authorization: Bearer $TOKEN" -X PATCH https://$brokerHost/broker/rest/domains/$appDomain/members --data-urlencode role=view --data-urlencode login=$dev 2>> $logfile| tee -a $logfile )
    status=$(exit_code "$response")
    if [ $status != 0 ];then
        echo "Error granting developer permissions. Openshift API exit code $status" &>>$logfile
    fi
done

json 0 "Success" $TOKEN "$appDomain.$platformDomain"
exit 0
